import cv2
import numpy as np

INPUT_IMAGE = "test_image.png" 
OUTPUT_W, OUTPUT_H = 400, 400
PRECISION = 8


def generate():
    img_bgr = cv2.imread(INPUT_IMAGE)
    if img_bgr is None: return
    img = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
    h_in, w_in, _ = img.shape

    with open("image_in_24b.hex", "w") as f:
        for y in range(h_in):
            for x in range(w_in):
                r, g, b = img[y,x]
                f.write(f"{r:02x}{g:02x}{b:02x}\n") 

    scale_x = (w_in << PRECISION) // OUTPUT_W
    scale_y = (h_in << PRECISION) // OUTPUT_H

    with open("expected_out_24b.hex", "w") as f:
        for y_out in range(OUTPUT_H):
            for x_out in range(OUTPUT_W):
                xf, yf = x_out * scale_x, y_out * scale_y
                x0, y0 = xf >> PRECISION, yf >> PRECISION
                a, b = xf & 255, yf & 255
                x1, y1 = min(x0+1, w_in-1), min(y0+1, h_in-1)
                x0, y0 = min(x0, w_in-1), min(y0, h_in-1)

                r_val, g_val, b_val = 0, 0, 0
                for c in range(3):
                    p00, p10 = int(img[y0,x0,c]), int(img[y0,x1,c])
                    p01, p11 = int(img[y1,x0,c]), int(img[y1,x1,c])
                    val = ((256-a)*(256-b)*p00 + a*(256-b)*p10 + (256-a)*b*p01 + a*b*p11) >> 16
                    final = max(0, min(255, val))
                    
                    if c == 0: r_val = final
                    elif c == 1: g_val = final
                    else: b_val = final
                
                f.write(f"{r_val:02x}{g_val:02x}{b_val:02x}\n")

    print("✅ 24-bit Hex files generated!")

if __name__ == "__main__":
    generate()