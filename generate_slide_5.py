import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import pymupdf

def create_rounded_rect_mask(size, radius):
    mask = Image.new('L', size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask

def draw_hud_corners(draw, rect, color, length=18, width=2):
    x1, y1, x2, y2 = rect
    # Top-left
    draw.line([(x1, y1), (x1 + length, y1)], fill=color, width=width)
    draw.line([(x1, y1), (x1, y1 + length)], fill=color, width=width)
    # Top-right
    draw.line([(x2, y1), (x2 - length, y1)], fill=color, width=width)
    draw.line([(x2, y1), (x2, y1 + length)], fill=color, width=width)
    # Bottom-left
    draw.line([(x1, y2), (x1 + length, y2)], fill=color, width=width)
    draw.line([(x1, y2), (x1, y2 - length)], fill=color, width=width)
    # Bottom-right
    draw.line([(x2, y2), (x2 - length, y2)], fill=color, width=width)
    draw.line([(x2, y2), (x2, y2 - length)], fill=color, width=width)

def draw_custom_icon(draw, icon_type, center_x, center_y, size, color):
    r = size // 2
    x0 = center_x - r
    y0 = center_y - r
    x1 = center_x + r
    y1 = center_y + r
    
    if icon_type == "p2p_mesh":
        # Central hub with 3 satellite nodes
        draw.ellipse([(center_x - 3, center_y - 3), (center_x + 3, center_y + 3)], fill=color)
        n1 = (center_x - 7, center_y - 6)
        n2 = (center_x + 7, center_y - 5)
        n3 = (center_x, center_y + 8)
        for nx, ny in [n1, n2, n3]:
            draw.line([(center_x, center_y), (nx, ny)], fill=color, width=1)
            draw.ellipse([(nx - 2, ny - 2), (nx + 2, ny + 2)], fill=color)
            
    elif icon_type == "instant_sos":
        # Concentric glowing beacon rings and exclamation
        draw.ellipse([(center_x - 9, center_y - 9), (center_x + 9, center_y + 9)], outline=color, width=1)
        draw.ellipse([(center_x - 5, center_y - 5), (center_x + 5, center_y + 5)], outline=color, width=1)
        draw.line([(center_x, center_y - 3), (center_x, center_y + 1)], fill=color, width=2)
        draw.point((center_x, center_y + 3), fill=color)
        
    elif icon_type == "offline_map":
        # Tactical diamond / map waypoint
        draw.polygon([(center_x, y0 + 2), (x1 - 2, center_y), (center_x, y1 - 2), (x0 + 2, center_y)], outline=color, width=1)
        draw.line([(center_x - 4, center_y), (center_x + 4, center_y)], fill=color, width=1)
        draw.line([(center_x, center_y - 4), (center_x, center_y + 4)], fill=color, width=1)
        draw.ellipse([(center_x - 2, center_y - 2), (center_x + 2, center_y + 2)], fill=color)
        
    elif icon_type == "edge_ai":
        # Microchip brain processor
        draw.rectangle([(center_x - 6, center_y - 6), (center_x + 6, center_y + 6)], outline=color, width=1)
        draw.rectangle([(center_x - 3, center_y - 3), (center_x + 3, center_y + 3)], fill=color)
        # Pins
        for p in [-4, 0, 4]:
            draw.line([(center_x + p, center_y - 9), (center_x + p, center_y - 6)], fill=color, width=1)
            draw.line([(center_x + p, center_y + 6), (center_x + p, center_y + 9)], fill=color, width=1)
            draw.line([(center_x - 9, center_y + p), (center_x - 6, center_y + p)], fill=color, width=1)
            draw.line([(center_x + 6, center_y + p), (center_x + 9, center_y + p)], fill=color, width=1)
            
    elif icon_type == "dbscan":
        # Cluster of data points with boundary
        draw.ellipse([(center_x - 9, center_y - 8), (center_x + 9, center_y + 8)], outline=color, width=1)
        draw.ellipse([(center_x - 4, center_y - 3), (center_x - 2, center_y - 1)], fill=color)
        draw.ellipse([(center_x + 3, center_y - 4), (center_x + 5, center_y - 2)], fill=color)
        draw.ellipse([(center_x, center_y + 2), (center_x + 2, center_y + 4)], fill=color)
        draw.ellipse([(center_x - 5, center_y + 3), (center_x - 3, center_y + 5)], fill=color)
        
    elif icon_type == "gis_radar":
        # Tactical Radar sweep
        draw.ellipse([(center_x - 8, center_y - 8), (center_x + 8, center_y + 8)], outline=color, width=1)
        draw.line([(center_x - 8, center_y), (center_x + 8, center_y)], fill=color, width=1)
        draw.line([(center_x, center_y - 8), (center_x, center_y + 8)], fill=color, width=1)
        draw.line([(center_x, center_y), (center_x + 6, center_y - 6)], fill=color, width=1)
        
    elif icon_type == "milp_fleet":
        # Vehicle / route dispatch arrow
        draw.polygon([(center_x, center_y - 8), (center_x + 8, center_y + 6), (center_x, center_y + 3), (center_x - 8, center_y + 6)], outline=color, width=1)
        draw.line([(center_x, center_y - 3), (center_x, center_y + 2)], fill=color, width=1)
        
    elif icon_type == "cap_feeds":
        # Broadcast broadcast tower waves
        draw.polygon([(center_x, center_y - 7), (center_x - 4, center_y + 7), (center_x + 4, center_y + 7)], outline=color, width=1)
        draw.ellipse([(center_x - 1, center_y - 8), (center_x + 1, center_y - 6)], fill=color)
        draw.arc([(center_x - 8, center_y - 9), (center_x + 8, center_y + 7)], 210, 330, fill=color, width=1)

def make_phone_mockup(screen_img, target_width=235, target_height=470, accent_color=(0, 255, 136)):
    bezel_h = 9
    bezel_v = 11
    corner_r = 28
    
    phone_w = target_width
    phone_h = target_height
    screen_w = phone_w - (bezel_h * 2)
    screen_h = phone_h - (bezel_v * 2)
    
    screen_resized = screen_img.resize((screen_w, screen_h), Image.Resampling.LANCZOS)
    screen_mask = create_rounded_rect_mask((screen_w, screen_h), radius=20)
    
    phone = Image.new('RGBA', (phone_w, phone_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(phone)
    
    # Outer phone chassis (stealth titanium)
    draw.rounded_rectangle(
        [(0, 0), (phone_w - 1, phone_h - 1)],
        radius=corner_r,
        fill=(14, 20, 18, 255),
        outline=(accent_color[0], accent_color[1], accent_color[2], 220),
        width=2
    )
    
    # Inner border
    draw.rounded_rectangle(
        [(2, 2), (phone_w - 3, phone_h - 3)],
        radius=corner_r - 2,
        fill=(8, 12, 10, 255),
        outline=(25, 45, 35, 255),
        width=1
    )
    
    # Paste screen
    phone.paste(screen_resized, (bezel_h, bezel_v), screen_mask)
    
    # Dynamic Island / speaker notch
    notch_w = int(phone_w * 0.32)
    notch_h = 10
    notch_x = (phone_w - notch_w) // 2
    notch_y = bezel_v + 3
    draw.rounded_rectangle(
        [(notch_x, notch_y), (notch_x + notch_w, notch_y + notch_h)],
        radius=5,
        fill=(4, 6, 5, 255)
    )
    # Lens
    draw.ellipse(
        [(notch_x + notch_w - 12, notch_y + 2), (notch_x + notch_w - 8, notch_y + 6)],
        fill=(25, 45, 60, 255)
    )
    
    return phone

def make_browser_mockup(screen_img, target_width=700, target_height=470, font_consola=None, font_bahn=None):
    header_h = 36
    corner_r = 12
    
    screen_w = target_width - 4
    screen_h = target_height - header_h - 2
    
    screen_resized = screen_img.resize((screen_w, screen_h), Image.Resampling.LANCZOS)
    screen_mask = create_rounded_rect_mask((screen_w, screen_h), radius=6)
    
    window = Image.new('RGBA', (target_width, target_height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(window)
    
    # Window chassis with cyan glowing border
    draw.rounded_rectangle(
        [(0, 0), (target_width - 1, target_height - 1)],
        radius=corner_r,
        fill=(10, 18, 20, 255),
        outline=(0, 229, 255, 220),
        width=2
    )
    
    # Header bar
    header_img = Image.new('RGBA', (target_width, header_h), (14, 26, 28, 255))
    h_draw = ImageDraw.Draw(header_img)
    # Controls
    h_draw.ellipse([(14, 12), (23, 21)], fill=(255, 95, 86, 255))
    h_draw.ellipse([(30, 12), (39, 21)], fill=(255, 189, 46, 255))
    h_draw.ellipse([(46, 12), (55, 21)], fill=(39, 201, 63, 255))
    
    # URL address bar
    addr_w = int(target_width * 0.48)
    addr_x = (target_width - addr_w) // 2
    h_draw.rounded_rectangle(
        [(addr_x, 7), (addr_x + addr_w, 29)],
        radius=5,
        fill=(20, 36, 40, 255),
        outline=(40, 75, 80, 255),
        width=1
    )
    if font_consola:
        h_draw.text((addr_x + 14, 9), "https://command.rakshanet.in/live-overview", font=font_consola, fill=(130, 220, 210, 255))
        
    # Status chip
    status_x = target_width - 165
    h_draw.rounded_rectangle(
        [(status_x, 7), (status_x + 152, 29)],
        radius=5,
        fill=(5, 36, 30, 255),
        outline=(0, 255, 136, 180),
        width=1
    )
    h_draw.ellipse([(status_x + 8, 14), (status_x + 16, 22)], fill=(0, 255, 136, 255))
    if font_bahn:
        h_draw.text((status_x + 22, 9), "LIVE INGESTION (OK)", font=font_bahn, fill=(0, 255, 136, 255))
        
    window.paste(header_img, (0, 0))
    draw.line([(0, header_h), (target_width, header_h)], fill=(25, 55, 60, 255), width=1)
    window.paste(screen_resized, (2, header_h + 1), screen_mask)
    
    return window

def build_feature_card(width, height, icon_type, title, desc, accent_color, font_title, font_desc):
    card = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(card)
    
    # Background glass
    draw.rounded_rectangle(
        [(0, 0), (width - 1, height - 1)],
        radius=8,
        fill=(6, 18, 14, 230),
        outline=(accent_color[0], accent_color[1], accent_color[2], 130),
        width=1
    )
    
    # Icon circle / badge on left
    badge_size = 32
    badge_x = 10
    badge_y = (height - badge_size) // 2
    draw.rounded_rectangle(
        [(badge_x, badge_y), (badge_x + badge_size, badge_y + badge_size)],
        radius=6,
        fill=(accent_color[0]//6, accent_color[1]//5, accent_color[2]//5, 255),
        outline=(accent_color[0], accent_color[1], accent_color[2], 220),
        width=1
    )
    
    # Draw custom vector icon inside the badge!
    draw_custom_icon(draw, icon_type, badge_x + badge_size//2, badge_y + badge_size//2, 22, accent_color)
    
    # Title & description
    text_x = badge_x + badge_size + 12
    draw.text((text_x, 8), title, font=font_title, fill=(255, 255, 255, 255))
    draw.text((text_x, 32), desc, font=font_desc, fill=(195, 228, 215, 255))
    
    return card

def generate_slide_5():
    base_path = r'C:\Users\Prana\.gemini\antigravity\brain\4f3a9134-7a56-4f1b-a67b-a9fd8aad13be\pdf_slides\page_5.png'
    slide = Image.open(base_path).convert('RGBA')
    W, H = slide.size
    print(f"Base slide dimensions: {W}x{H}")
    
    # Load fonts
    font_bahn_large = ImageFont.truetype(r'C:\Windows\Fonts\bahnschrift.ttf', 35)
    font_bahn_sub = ImageFont.truetype(r'C:\Windows\Fonts\bahnschrift.ttf', 17)
    font_bahn_badge = ImageFont.truetype(r'C:\Windows\Fonts\bahnschrift.ttf', 14)
    font_bahn_meta = ImageFont.truetype(r'C:\Windows\Fonts\consola.ttf', 13)
    font_bahn_feat_t = ImageFont.truetype(r'C:\Windows\Fonts\bahnschrift.ttf', 16)
    font_bahn_feat_d = ImageFont.truetype(r'C:\Windows\Fonts\bahnschrift.ttf', 13)
    
    font_consola_url = ImageFont.truetype(r'C:\Windows\Fonts\consola.ttf', 12)
    font_consola_stat = ImageFont.truetype(r'C:\Windows\Fonts\consola.ttf', 13)
    
    # Load screenshots
    screen_mobile_sos = Image.open(r'p:\RakshaNet\video\assets\screens\mobile_03_home_sos.png')
    screen_mobile_map = Image.open(r'p:\RakshaNet\video\assets\screens\mobile_06_live_map.png')
    screen_web_dash = Image.open(r'p:\RakshaNet\video\assets\screens\web_dashboard.png')
    
    # Left 62% Region:
    # Width = 1530 px (Ends at x=1610, leaving right 38% sci-fi city untouched)
    col_gap = 35
    col_width = (1530 - col_gap) // 2  # ~747 px each
    
    col1_x = 75
    col2_x = col1_x + col_width + col_gap
    col_y = 405
    col_height = 895
    
    overlay = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    draw_ov = ImageDraw.Draw(overlay)
    
    # ==========================================
    # COLUMN 1: MOBILE APK CONTAINER CARD
    # ==========================================
    card1_bg = (4, 18, 12, 230)
    card1_border = (0, 255, 136, 180)
    
    draw_ov.rounded_rectangle(
        [(col1_x, col_y), (col1_x + col_width, col_y + col_height)],
        radius=16,
        fill=card1_bg,
        outline=card1_border,
        width=2
    )
    # HUD Corner Reticles on Card 1
    draw_hud_corners(draw_ov, (col1_x, col_y, col1_x + col_width, col_y + col_height), (0, 255, 136, 255), length=22, width=3)
    
    # Top cyber accent lines
    draw_ov.line(
        [(col1_x + 35, col_y + 2), (col1_x + col_width - 35, col_y + 2)],
        fill=(0, 255, 136, 255),
        width=3
    )
    
    # Badge Pill 1
    b1_text = "CITIZEN & FIRST RESPONDER FIELD SUITE"
    draw_ov.rounded_rectangle(
        [(col1_x + 25, col_y + 18), (col1_x + 345, col_y + 42)],
        radius=5,
        fill=(0, 45, 25, 255),
        outline=(0, 255, 136, 200),
        width=1
    )
    draw_ov.text((col1_x + 36, col_y + 22), b1_text, font=font_bahn_badge, fill=(0, 255, 136, 255))
    
    # Tech Metadata tag on right side of header
    draw_ov.text((col1_x + col_width - 235, col_y + 22), "[ BLE 5.2 + WI-FI MESH ]", font=font_bahn_meta, fill=(0, 255, 136, 180))
    
    # Title & Subtitle
    draw_ov.text((col1_x + 25, col_y + 50), "RakshaNet Mobile (Android APK)", font=font_bahn_large, fill=(255, 255, 255, 255))
    draw_ov.text((col1_x + 25, col_y + 92), "Zero-Internet Peer-to-Peer Mesh Network & Tactical SOS", font=font_bahn_sub, fill=(120, 220, 175, 255))
    
    # Mobile Phone Mockups
    phone_w = 235
    phone_h = 470
    phone1_x = col1_x + 90
    phone2_x = col1_x + col_width - phone_w - 90
    phone_y = col_y + 128
    
    phone_sos = make_phone_mockup(screen_mobile_sos, target_width=phone_w, target_height=phone_h, accent_color=(255, 80, 80))
    phone_map = make_phone_mockup(screen_mobile_map, target_width=phone_w, target_height=phone_h, accent_color=(0, 255, 136))
    
    overlay.paste(phone_sos, (phone1_x, phone_y), phone_sos)
    overlay.paste(phone_map, (phone2_x, phone_y), phone_map)
    
    # Badges below phones
    p1_badge_x = phone1_x + (phone_w - 146) // 2
    draw_ov.rounded_rectangle(
        [(p1_badge_x, phone_y + phone_h + 8), (p1_badge_x + 146, phone_y + phone_h + 28)],
        radius=5,
        fill=(40, 15, 15, 240),
        outline=(255, 75, 75, 180),
        width=1
    )
    draw_ov.text((p1_badge_x + 12, phone_y + phone_h + 10), "SOS BEACON SCREEN", font=font_bahn_badge, fill=(255, 120, 120, 255))
    
    p2_badge_x = phone2_x + (phone_w - 150) // 2
    draw_ov.rounded_rectangle(
        [(p2_badge_x, phone_y + phone_h + 8), (p2_badge_x + 150, phone_y + phone_h + 28)],
        radius=5,
        fill=(10, 35, 22, 240),
        outline=(0, 255, 136, 180),
        width=1
    )
    draw_ov.text((p2_badge_x + 10, phone_y + phone_h + 10), "OFFLINE TOPO MAP", font=font_bahn_badge, fill=(0, 255, 136, 255))
    
    # Key Feature Cards (2x2 grid)
    feat_y1 = col_y + 648
    feat_y2 = feat_y1 + 105
    card_w = (col_width - 50 - 15) // 2  # ~335 px
    card_h = 95
    
    fc1_x = col1_x + 25
    fc2_x = fc1_x + card_w + 15
    
    f1 = build_feature_card(card_w, card_h, "p2p_mesh", "P2P Zero-Internet Mesh", "BLE & Wi-Fi Direct store-and-forward\nrelays packets across 15+ hops seamlessly.", (0, 255, 136), font_bahn_feat_t, font_bahn_feat_d)
    f2 = build_feature_card(card_w, card_h, "instant_sos", "One-Tap Instant SOS", "3-second tactile hold triggers encrypted\ndistress beacon with GPS & triage data.", (255, 90, 80), font_bahn_feat_t, font_bahn_feat_d)
    f3 = build_feature_card(card_w, card_h, "offline_map", "Offline Tactical Maps", "Cached OpenStreetMap vector tiles & peer\nproximity circles with zero cellular coverage.", (0, 229, 255), font_bahn_feat_t, font_bahn_feat_d)
    f4 = build_feature_card(card_w, card_h, "edge_ai", "On-Device Edge AI", "Offline intelligence engine for medical triage,\nsurvival guidance & resource allocation.", (255, 210, 31), font_bahn_feat_t, font_bahn_feat_d)
    
    overlay.paste(f1, (fc1_x, feat_y1), f1)
    overlay.paste(f2, (fc2_x, feat_y1), f2)
    overlay.paste(f3, (fc1_x, feat_y2), f3)
    overlay.paste(f4, (fc2_x, feat_y2), f4)
    
    # ==========================================
    # COLUMN 2: WEB COMMAND CENTER CARD
    # ==========================================
    card2_bg = (6, 16, 22, 230)
    card2_border = (0, 229, 255, 180)
    
    draw_ov.rounded_rectangle(
        [(col2_x, col_y), (col2_x + col_width, col_y + col_height)],
        radius=16,
        fill=card2_bg,
        outline=card2_border,
        width=2
    )
    # HUD Corner Reticles on Card 2
    draw_hud_corners(draw_ov, (col2_x, col_y, col2_x + col_width, col_y + col_height), (0, 229, 255, 255), length=22, width=3)
    
    # Top cyber accent lines
    draw_ov.line(
        [(col2_x + 35, col_y + 2), (col2_x + col_width - 35, col_y + 2)],
        fill=(0, 229, 255, 255),
        width=3
    )
    
    # Badge Pill 2
    b2_text = "TACTICAL DISASTER COMMAND & AGENCY HQ"
    draw_ov.rounded_rectangle(
        [(col2_x + 25, col_y + 18), (col2_x + 355, col_y + 42)],
        radius=5,
        fill=(0, 35, 45, 255),
        outline=(0, 229, 255, 200),
        width=1
    )
    draw_ov.text((col2_x + 36, col_y + 22), b2_text, font=font_bahn_badge, fill=(0, 229, 255, 255))
    
    # Tech Metadata tag on right side of header
    draw_ov.text((col2_x + col_width - 235, col_y + 22), "[ DUAL DB: SQLITE + MONGO ]", font=font_bahn_meta, fill=(0, 229, 255, 180))
    
    # Title & Subtitle
    draw_ov.text((col2_x + 25, col_y + 50), "RakshaNet Command Center", font=font_bahn_large, fill=(255, 255, 255, 255))
    draw_ov.text((col2_x + 25, col_y + 92), "Real-Time Tactical GIS, AI Triage & Fleet Optimization", font=font_bahn_sub, fill=(120, 215, 235, 255))
    
    # Desktop Browser Mockup
    browser_w = col_width - 50  # ~697 px
    browser_h = 470
    browser_x = col2_x + 25
    browser_y = col_y + 128
    
    browser_mockup = make_browser_mockup(
        screen_web_dash,
        target_width=browser_w,
        target_height=browser_h,
        font_consola=font_consola_url,
        font_bahn=font_consola_stat
    )
    overlay.paste(browser_mockup, (browser_x, browser_y), browser_mockup)
    
    # Badge below browser
    b_badge_x = browser_x + (browser_w - 230) // 2
    draw_ov.rounded_rectangle(
        [(b_badge_x, browser_y + browser_h + 8), (b_badge_x + 230, browser_y + browser_h + 28)],
        radius=5,
        fill=(10, 28, 36, 240),
        outline=(0, 229, 255, 180),
        width=1
    )
    draw_ov.text((b_badge_x + 12, browser_y + browser_h + 10), "OVERVIEW & TRIAGE DASHBOARD", font=font_bahn_badge, fill=(0, 229, 255, 255))
    
    # Key Feature Cards (2x2 grid for Web Command Center)
    wfc1_x = col2_x + 25
    wfc2_x = wfc1_x + card_w + 15
    
    wf1 = build_feature_card(card_w, card_h, "dbscan", "DBSCAN Cluster Engine", "Spatial AI clusters scattered SOS calls into\nprioritized incidents with casualty counts.", (0, 229, 255), font_bahn_feat_t, font_bahn_feat_d)
    wf2 = build_feature_card(card_w, card_h, "gis_radar", "Tactical GIS & Black Holes", "Tracks mesh relays, mobile nodes & detects\ntelemetry black holes (>75% packet loss).", (0, 255, 136), font_bahn_feat_t, font_bahn_feat_d)
    wf3 = build_feature_card(card_w, card_h, "milp_fleet", "MILP Fleet Optimization", "Mathematical solver optimizes dispatch for\nNDRF boats, 4WD vehicles & paramedics.", (255, 210, 31), font_bahn_feat_t, font_bahn_feat_d)
    wf4 = build_feature_card(card_w, card_h, "cap_feeds", "CAP v1.2 & CAD Feeds", "Standardized XML & JSON feeds for NDMA,\nSDRF & emergency response interoperability.", (255, 120, 220), font_bahn_feat_t, font_bahn_feat_d)
    
    overlay.paste(wf1, (wfc1_x, feat_y1), wf1)
    overlay.paste(wf2, (wfc2_x, feat_y1), wf2)
    overlay.paste(wf3, (wfc1_x, feat_y2), wf3)
    overlay.paste(wf4, (wfc2_x, feat_y2), wf4)
    
    # Composite overlay onto base slide
    final_slide = Image.alpha_composite(slide, overlay)
    
    # Save output images
    out_path = r'C:\Users\Prana\.gemini\antigravity\brain\4f3a9134-7a56-4f1b-a67b-a9fd8aad13be\pdf_slides\page_5.png'
    final_slide.convert('RGB').save(out_path, quality=95)
    print(f"Saved generated slide to {out_path}")
    
    ws_out = r'p:\RakshaNet\slide_page_5_ui_ux.png'
    final_slide.convert('RGB').save(ws_out, quality=95)
    print(f"Saved copy to {ws_out}")
    
    # Also update presentation PDF!
    pdf_in = r'p:\RakshaNet\template_backup.pdf'
    pdf_out = r'p:\RakshaNet\RakshaNet_CODE_APEX_Presentation.pdf'
    if os.path.exists(pdf_in):
        doc = pymupdf.open(pdf_in)
        # Page 5 is index 4
        page = doc[4]
        # Clean page images and insert new image
        rect = page.rect
        # PyMuPDF lets us insert image over the page
        page.insert_image(rect, filename=ws_out)
        doc.save(pdf_out)
        doc.close()
        print(f"Successfully generated presentation PDF with updated Page 5 at {pdf_out}")

if __name__ == "__main__":
    generate_slide_5()
