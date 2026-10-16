"""Baut die Seewald-Bodentiles über das pixel-plugin (MCP-Server pixel-mcp -> Aseprite) – TESTSTAND 15.10.2026.

Normalerweise nutzt du das Plugin direkt in Claude Code (die Tools heißen dort mcp__aseprite__*).
Dieses Skript spricht denselben MCP-Server ohne Claude Code an, damit der Ablauf nachvollziehbar
und wiederholbar ist. Jeder Schritt ist ein Tool-Aufruf des Plugins:
  create_canvas 32x32 RGB -> set_palette (hexen_palette.gpl) -> Ebenen "Boden" + "Laub & Details"
  -> 7 Frames (je Variante einer) -> draw_rectangle + draw_pixels -> save_as .aseprite
  -> export_sprite je Frame als PNG -> get_pixels zur Kontrolle (Pixel zurücklesen und vergleichen).
Danach werden die PNGs verlustfrei von RGBA nach RGB umgeschrieben (wie die bestehenden Bodentiles);
export_sprite des Plugins schreibt immer RGBA.

Aufruf:
  set PIXEL_MCP_BIN=<Pfad zu pixel-mcp bzw. pixel-mcp-windows-amd64.exe aus dem Plugin-Ordner>
  python seewald_waldboden_plugin.py <design_spec.json> <palette.gpl> <ziel.aseprite> <png-ordner> <protokoll.json>
Voraussetzung: ~/.config/pixel-mcp/config.json mit aseprite_path (legt /pixel-setup an).
"""
import json, os, subprocess, sys, time
import numpy as np
from PIL import Image


class MCP:
    """Minimaler MCP-stdio-Client (JSON-RPC 2.0, eine Nachricht pro Zeile)."""
    def __init__(self, cmd):
        self.p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, bufsize=1)
        self.i = 0
        self.calls = []
        self.server_info = self.req('initialize', {"protocolVersion": "2024-11-05", "capabilities": {},
                                                   "clientInfo": {"name": "bitterbloom-tiles", "version": "1.0"}})['result'].get('serverInfo')
        self.p.stdin.write(json.dumps({"jsonrpc": "2.0", "method": "notifications/initialized", "params": {}}) + "\n"); self.p.stdin.flush()

    def req(self, method, params):
        self.i += 1
        self.p.stdin.write(json.dumps({"jsonrpc": "2.0", "id": self.i, "method": method, "params": params}) + "\n"); self.p.stdin.flush()
        while True:
            line = self.p.stdout.readline()
            if not line:
                raise RuntimeError("pixel-mcp beendet (config.json / aseprite_path prüfen)")
            msg = json.loads(line)
            if msg.get('id') == self.i:
                return msg

    def call(self, name, args):
        t = time.time()
        r = self.req('tools/call', {"name": name, "arguments": args})
        res = r.get('result') or {}
        err = r.get('error') or (res.get('isError') and res)
        text = "\n".join(c.get('text', '') for c in res.get('content', []) if c.get('type') == 'text')
        self.calls.append({"tool": name, "ok": not err, "secs": round(time.time() - t, 2), "result": (text or json.dumps(err))[:200]})
        if err:
            raise RuntimeError(f"{name} fehlgeschlagen: {json.dumps(err)[:500]}")
        return text

    def close(self):
        self.p.stdin.close(); self.p.wait(timeout=10)


def main():
    SPEC, GPL, ASE_OUT, PNG_DIR, PROTO = sys.argv[1:6]
    spec = json.load(open(SPEC))
    hexc = lambda c: '#%02X%02X%02X' % tuple(int(v) for v in c[:3])
    pal = []
    for line in open(GPL, encoding='utf-8'):
        p = line.split()
        if len(p) >= 4 and all(t.isdigit() for t in p[:3]):
            pal.append('#%02X%02X%02X' % tuple(int(t) for t in p[:3]))
    m = MCP([os.environ["PIXEL_MCP_BIN"]])
    path = json.loads(m.call('create_canvas', {"width": 32, "height": 32, "color_mode": "rgb"}))['file_path']
    m.call('set_palette', {"sprite_path": path, "colors": pal})
    m.call('add_layer', {"sprite_path": path, "layer_name": "Boden"})
    m.call('add_layer', {"sprite_path": path, "layer_name": "Laub & Details"})
    m.call('delete_layer', {"sprite_path": path, "layer_name": "Layer 1"})
    for _ in range(len(spec["tiles"]) - 1):
        m.call('add_frame', {"sprite_path": path, "duration_ms": 200})
    for f, t in enumerate(spec["tiles"], start=1):
        soil = np.array(t["soil"], np.uint8); det = np.array(t["details"], np.uint8)
        vals, cnt = np.unique(soil.reshape(-1, 3), axis=0, return_counts=True); base = vals[cnt.argmax()]
        m.call('draw_rectangle', {"sprite_path": path, "layer_name": "Boden", "frame_number": f,
                                  "x": 0, "y": 0, "width": 32, "height": 32, "color": hexc(base), "filled": True})
        px = [{"x": x, "y": y, "color": hexc(soil[y, x])} for y in range(32) for x in range(32) if (soil[y, x] != base).any()]
        if px:
            m.call('draw_pixels', {"sprite_path": path, "layer_name": "Boden", "frame_number": f, "pixels": px})
        dp = [{"x": x, "y": y, "color": hexc(det[y, x])} for y in range(32) for x in range(32) if det[y, x, 3] == 255]
        if dp:
            m.call('draw_pixels', {"sprite_path": path, "layer_name": "Laub & Details", "frame_number": f, "pixels": dp})
    os.makedirs(os.path.dirname(ASE_OUT), exist_ok=True); os.makedirs(PNG_DIR, exist_ok=True)
    m.call('save_as', {"sprite_path": path, "output_path": ASE_OUT})
    for f, t in enumerate(spec["tiles"], start=1):
        m.call('export_sprite', {"sprite_path": ASE_OUT, "output_path": f'{PNG_DIR}/{t["name"]}.png', "format": "png", "frame_number": f})
    # Kontrolle: Ebenen-Pixel über das Plugin zurücklesen. Achtung: get_pixels bricht bei leeren Ebenen ab.
    bad = 0
    for f, t in enumerate(spec["tiles"], start=1):
        for layer, arr in (("Boden", np.array(t["soil"], np.uint8)), ("Laub & Details", np.array(t["details"], np.uint8))):
            r = json.loads(m.call('get_pixels', {"sprite_path": ASE_OUT, "layer_name": layer, "frame_number": f,
                                                 "x": 0, "y": 0, "width": 32, "height": 32, "page_size": 2000}))
            for p in r["pixels"]:
                c = p["color"].lstrip('#'); got = tuple(int(c[i:i + 2], 16) for i in (0, 2, 4, 6))
                want = tuple(int(v) for v in arr[p["y"], p["x"]]) + ((255,) if arr.shape[2] == 3 else ())
                if not (got[3] == 0 and want[3] == 0) and got != want:
                    bad += 1
    m.close()
    # RGBA -> RGB (verlustfrei, alle Pixel voll deckend), damit das Format den bestehenden Bodentiles entspricht
    for t in spec["tiles"]:
        p = f'{PNG_DIR}/{t["name"]}.png'
        a = np.array(Image.open(p).convert('RGBA'))
        assert (a[..., 3] == 255).all(), p
        Image.fromarray(a[..., :3], 'RGB').save(p, optimize=True)
    json.dump({"server": m.server_info, "abweichende_pixel": bad, "aufrufe": m.calls}, open(PROTO, 'w'), indent=1, ensure_ascii=False)
    print("fertig:", len(m.calls), "Plugin-Aufrufe, abweichende Pixel:", bad)


if __name__ == '__main__':
    main()
