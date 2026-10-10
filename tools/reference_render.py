"""
Reference renderer for CharacterKit specs (Pillow only).

Mirrors CharacterRenderer.swift so you can check the web preview and the Swift output
against the same picture. Draws every expression at rest (no blink, no look offset).

    pip install pillow
    python tools/reference_render.py Sources/CharacterKit/Resources/blobby.json out.png
"""
import math, json
from PIL import Image, ImageDraw, ImageChops, ImageFont

SS = 3  # supersampling

def clamp(v, lo, hi): return max(lo, min(hi, v))
def sgn(x): return -1.0 if x < 0 else 1.0
def hexc(h):
    h = h.lstrip('#'); return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def cubic(p0, c1, c2, p1, n=32):
    pts = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        x = u**3*p0[0] + 3*u*u*t*c1[0] + 3*u*t*t*c2[0] + t**3*p1[0]
        y = u**3*p0[1] + 3*u*u*t*c1[1] + 3*u*t*t*c2[1] + t**3*p1[1]
        pts.append((x, y))
    return pts

def quad(p0, c, p1, n=24):
    pts = []
    for i in range(n + 1):
        t = i / n
        x = (1-t)**2*p0[0] + 2*(1-t)*t*c[0] + t**2*p1[0]
        y = (1-t)**2*p0[1] + 2*(1-t)*t*c[1] + t**2*p1[1]
        pts.append((x, y))
    return pts

def superellipse(exponent, rx, ry, cy, wobble=0.0, time=0.0, steps=120):
    p = 2.0 / exponent
    pts = []
    for i in range(steps + 1):
        th = i / steps * 2 * math.pi
        c, s_ = math.cos(th), math.sin(th)
        r = 1 + wobble * math.sin(3 * th + time * 1.4)
        pts.append((sgn(c) * abs(c) ** p * rx * r, cy + sgn(s_) * abs(s_) ** p * ry * r))
    return pts

def body_shapes(parts, time=0.0):
    """Returns a list of polygons that are all filled with the same gradient (union by overpainting)."""
    shape = parts["bodyShape"]
    if shape == "round":
        return [superellipse(2.0, 0.80, 0.74, 0.06)]
    if shape == "blob":
        return [superellipse(2.8, 0.80, 0.74, 0.06, wobble=0.012, time=time)]
    # cloud: rounded base plus overlapping circles along the top
    RX, RY, CY, E = 0.80, 0.70, 0.10, 2.4
    shapes = [superellipse(E, RX, RY, CY)]
    n = int(parts["bumps"])
    span = 0.95
    spacing = span / (n - 1)
    rho0 = 0.62 * spacing
    prot = parts["bumpiness"] * 1.6
    for i in range(n):
        x = -span / 2 + i * spacing
        u = abs(x) / (span / 2)
        ytop = CY - RY * (1 - min(abs(x) / RX, 1.0) ** E) ** (1 / E)
        p_i = prot * (1.15 - 0.5 * u * u)
        rho = rho0 * (1 + 0.04 * math.sin(time * 1.6 + i * 1.7))
        cy = ytop + rho - p_i
        shapes.append([(x + rho * math.cos(a), cy + rho * math.sin(a)) for a in [k / 48 * 2 * math.pi for k in range(48)]])
    return shapes

def render(spec, pose, size=480, look=(0.0, 0.0), blink=1.0, squash=0.0, breath=0.0, stage="#EBD9FA", label=None):
    parts, pal = spec["parts"], spec["palette"]
    W = H = size * SS
    side = min(W, H)
    img = Image.new("RGB", (W, H), hexc(stage))

    sq = pose["bodySquash"] * 0.8 + squash
    sx = 1 + 0.12 * sq - 0.008 * breath
    sy = 1 - 0.12 * sq + 0.015 * breath
    anchor = 0.80

    def tp(pt):  # unit -> pixel
        x, y = pt
        x2 = x * sx
        y2 = anchor + (y - anchor) * sy
        return (W / 2 + x2 * side / 2, H / 2 + y2 * side / 2)

    def poly_mask(points):
        m = Image.new("L", (W, H), 0)
        ImageDraw.Draw(m).polygon([tp(p) for p in points], fill=255)
        return m

    def stroke_mask(points, width, closed=False):
        m = Image.new("L", (W, H), 0)
        d = ImageDraw.Draw(m)
        pp = [tp(p) for p in points]
        if closed: pp = pp + [pp[0]]
        wpx = width * side / 2 * ((sx + sy) / 2)
        d.line(pp, fill=255, width=max(1, int(round(wpx))), joint="curve")
        r = wpx / 2
        for (x, y) in pp:
            d.ellipse([x - r, y - r, x + r, y + r], fill=255)
        return m

    # body with vertical gradient
    top, bot = hexc(pal["body"]), hexc(pal["bodyShade"])
    grad = Image.new("RGB", (W, H))
    gd = ImageDraw.Draw(grad)
    y0 = tp((0, -0.8))[1]; y1 = tp((0, 0.85))[1]
    for y in range(H):
        t = clamp((y - y0) / (y1 - y0), 0, 1)
        gd.line([(0, y), (W, y)], fill=tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3)))
    bm = Image.new("L", (W, H), 0)
    for shp in body_shapes(parts):
        bm = ImageChops.lighter(bm, poly_mask(shp))
    img.paste(grad, (0, 0), bm)

    # eyes
    es = 1.5 if parts["eyeCount"] == 1 else 1.0
    ew = 0.30 * parts["eyeSize"] * es
    eh = 0.32 * parts["eyeSize"] * es
    open_ = clamp(pose["eyeOpen"] * blink, 0, 1)
    cover = 1 - open_
    xs = [0.0] if parts["eyeCount"] == 1 else [-parts["eyeSpacing"], parts["eyeSpacing"]]
    tilt = pose["lidTilt"]
    for ex in xs:
        cy = parts["eyeY"]
        side_ = 0 if parts["eyeCount"] == 1 else (-1 if ex < 0 else 1)
        inner = -side_
        A = -eh / 2 + cover * eh * (1 + 0.55 * abs(tilt))
        B = (-tilt) * 0.55 * eh * inner / (ew / 2)
        yl = lambda xl: A + B * xl
        lid_poly = [(ex - ew, cy + yl(-ew)), (ex + ew, cy + yl(ew)), (ex + ew, cy + 2 * eh), (ex - ew, cy + 2 * eh)]
        ell = [(ex + ew / 2 * math.cos(a), cy + eh / 2 * math.sin(a)) for a in [i / 72 * 2 * math.pi for i in range(72)]]
        eye_mask = ImageChops.multiply(poly_mask(ell), poly_mask(lid_poly))
        img.paste(hexc(pal["eyeWhite"]), (0, 0), eye_mask)
        pr = ew * parts["pupilSize"] * 0.5
        pxc = ex + look[0] * ew * 0.24
        pyc = cy + look[1] * eh * 0.24
        pup = [(pxc + pr * math.cos(a), pyc + pr * math.sin(a)) for a in [i / 48 * 2 * math.pi for i in range(48)]]
        img.paste(hexc(pal["pupil"]), (0, 0), ImageChops.multiply(poly_mask(pup), eye_mask))

    # mouth
    mw = min(parts["mouthWidth"] * (0.6 + 0.8 * pose["mouthWidth"]), 0.9)
    my = parts["mouthY"]
    lw = 0.07 * parts["mouthThickness"]
    openH = pose["mouthOpen"] * 0.26
    ctrl = my + pose["mouthCurve"] * 0.44
    L, R = (-mw / 2, my), (mw / 2, my)
    topMidDy = pose["mouthCurve"] * 0.22
    cDy = (topMidDy + openH) / 0.75
    shape = quad(L, (0, ctrl), R) + cubic(R, (R[0], my + cDy), (L[0], my + cDy), L)
    fade = clamp(openH / 0.05, 0, 1)
    ow = 0.04 * fade
    if ow > 0.001:
        img.paste(hexc(pal["mouthOutline"]), (0, 0), stroke_mask(shape, lw + 2 * ow, closed=True))
    img.paste(hexc(pal["mouth"]), (0, 0), poly_mask(shape))
    img.paste(hexc(pal["mouth"]), (0, 0), stroke_mask(shape, lw, closed=True))

    img = img.resize((size, size), Image.LANCZOS)
    if label:
        d = ImageDraw.Draw(img)
        try: f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 18)
        except Exception: f = None
        d.text((14, 10), label, fill=(70, 40, 130), font=f)
    return img

def sheet(spec, names, cols=4, size=360, **kw):
    rows = math.ceil(len(names) / cols)
    out = Image.new("RGB", (cols * size, rows * size), (235, 217, 250))
    for i, n in enumerate(names):
        e = spec["expressions"][n]
        tile = render(spec, e, size=size, label=n, **kw)
        out.paste(tile, ((i % cols) * size, (i // cols) * size))
    return out


if __name__ == "__main__":
    import sys
    spec_path = sys.argv[1] if len(sys.argv) > 1 else "Sources/CharacterKit/Resources/blobby.json"
    out_path = sys.argv[2] if len(sys.argv) > 2 else "character-sheet.png"
    spec = json.load(open(spec_path))
    sheet(spec, list(spec["expressions"].keys())).save(out_path)
    print("wrote", out_path)
