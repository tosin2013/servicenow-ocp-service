#!/usr/bin/env python3
"""
Create PNG logo for ServiceNow-OpenShift Integration Documentation
This script generates a professional logo in PNG format
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_logo():
    # Logo dimensions
    width, height = 240, 48
    
    # Create image with transparent background
    img = Image.new('RGBA', (width, height), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors
    servicenow_blue = (25, 118, 210)  # #1976d2
    openshift_red = (238, 0, 0)       # #ee0000
    ansible_orange = (255, 102, 0)    # #ff6600
    text_gray = (102, 102, 102)       # #666666
    white = (255, 255, 255)
    
    # ServiceNow section (left)
    # Draw ServiceNow icon background
    draw.rounded_rectangle([8, 12, 28, 36], radius=3, fill=servicenow_blue)
    
    # ServiceNow "S" pattern
    draw.ellipse([12, 18, 24, 24], fill=white)
    draw.ellipse([14, 20, 22, 22], fill=servicenow_blue)
    
    # Small indicators
    draw.ellipse([13, 28, 17, 32], fill=white)
    draw.ellipse([19, 28, 23, 32], fill=white)
    
    # Integration arrows (center)
    # Arrow 1
    arrow_y = 24
    draw.polygon([(35, arrow_y), (50, arrow_y), (46, arrow_y-3), (50, arrow_y), (46, arrow_y+3)], 
                fill=ansible_orange)
    
    # Gear symbol
    center_x, center_y = 60, 24
    gear_radius = 6
    draw.ellipse([center_x-gear_radius, center_y-gear_radius, 
                 center_x+gear_radius, center_y+gear_radius], 
                outline=ansible_orange, width=2)
    
    # Gear teeth
    for i in range(4):
        angle = i * 90
        if i == 0:  # top
            draw.polygon([(center_x-2, center_y-gear_radius-2), 
                         (center_x+2, center_y-gear_radius-2),
                         (center_x, center_y-gear_radius)], fill=ansible_orange)
        elif i == 1:  # right
            draw.polygon([(center_x+gear_radius, center_y-2), 
                         (center_x+gear_radius, center_y+2),
                         (center_x+gear_radius+2, center_y)], fill=ansible_orange)
        elif i == 2:  # bottom
            draw.polygon([(center_x-2, center_y+gear_radius+2), 
                         (center_x+2, center_y+gear_radius+2),
                         (center_x, center_y+gear_radius)], fill=ansible_orange)
        elif i == 3:  # left
            draw.polygon([(center_x-gear_radius, center_y-2), 
                         (center_x-gear_radius, center_y+2),
                         (center_x-gear_radius-2, center_y)], fill=ansible_orange)
    
    # Arrow 2
    draw.polygon([(70, arrow_y), (85, arrow_y), (81, arrow_y-3), (85, arrow_y), (81, arrow_y+3)], 
                fill=ansible_orange)
    
    # OpenShift section (right)
    # Draw OpenShift hexagon
    hex_center_x, hex_center_y = 95, 24
    hex_size = 12
    
    # Hexagon points
    import math
    hex_points = []
    for i in range(6):
        angle = i * 60 * math.pi / 180
        x = hex_center_x + hex_size * math.cos(angle)
        y = hex_center_y + hex_size * math.sin(angle)
        hex_points.append((x, y))
    
    draw.polygon(hex_points, fill=openshift_red)
    
    # Inner hexagon (outline)
    inner_hex_points = []
    inner_size = 8
    for i in range(6):
        angle = i * 60 * math.pi / 180
        x = hex_center_x + inner_size * math.cos(angle)
        y = hex_center_y + inner_size * math.sin(angle)
        inner_hex_points.append((x, y))
    
    draw.polygon(inner_hex_points, outline=white, width=2)
    
    # Center dot
    draw.ellipse([hex_center_x-2, hex_center_y-2, hex_center_x+2, hex_center_y+2], fill=white)
    
    # Container layers
    draw.rectangle([88, 21, 102, 22], fill=white)
    draw.rectangle([88, 25, 102, 26], fill=white)
    draw.rectangle([88, 27, 102, 28], fill=white)
    
    # Text
    try:
        # Try to use a nice font
        font_large = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 11)
        font_small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 9)
    except:
        # Fallback to default font
        font_large = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    # ServiceNow text
    draw.text((125, 15), "ServiceNow", fill=servicenow_blue, font=font_large)
    
    # OpenShift text
    draw.text((125, 28), "OpenShift", fill=openshift_red, font=font_large)
    
    # Integration text
    draw.text((185, 22), "Integration", fill=text_gray, font=font_small)
    
    return img

def create_favicon():
    """Create a simplified favicon version"""
    # Favicon dimensions
    size = 32
    img = Image.new('RGBA', (size, size), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors
    servicenow_blue = (25, 118, 210)
    openshift_red = (238, 0, 0)
    ansible_orange = (255, 102, 0)
    white = (255, 255, 255)
    
    # Simple design for favicon
    # Left half - ServiceNow blue
    draw.rectangle([0, 0, 15, 31], fill=servicenow_blue)
    
    # Right half - OpenShift red
    draw.rectangle([16, 0, 31, 31], fill=openshift_red)
    
    # Center connection
    draw.rectangle([14, 14, 17, 17], fill=ansible_orange)
    
    # Small indicators
    draw.ellipse([4, 8, 8, 12], fill=white)
    draw.ellipse([4, 20, 8, 24], fill=white)
    draw.ellipse([24, 8, 28, 12], fill=white)
    draw.ellipse([24, 20, 28, 24], fill=white)
    
    return img

if __name__ == "__main__":
    # Create main logo
    logo = create_logo()
    logo.save("docs/content/assets/logo.png", "PNG")
    print("✅ Created logo.png")
    
    # Create favicon
    favicon = create_favicon()
    favicon.save("docs/content/assets/favicon.png", "PNG")
    
    # Also create ICO version for better browser support
    favicon.save("docs/content/assets/favicon.ico", "ICO")
    print("✅ Created favicon.png and favicon.ico")
    
    print("🎨 Logo creation complete!")
    print("📁 Files created in docs/content/assets/:")
    print("   - logo.svg (vector version)")
    print("   - logo.png (raster version)")
    print("   - favicon.png (32x32 favicon)")
    print("   - favicon.ico (ICO format favicon)")
