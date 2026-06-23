import numpy as np
import cv2
import os

try:
    from skimage.metrics import structural_similarity as ssim
except ImportError:
    pass

WIDTH, HEIGHT = 400, 400

def parse_24b(fn):
    print(f"Loading '{fn}'...")
    data = []
    with open(fn, 'r') as f:
        for line in f:
            clean = line.strip().lower()
            if not clean: continue
            if 'x' in clean or 'z' in clean:
                data.append([0, 0, 0]) 
            else:
                try:
                  
                    r = int(clean[0:2], 16)
                    g = int(clean[2:4], 16)
                    b = int(clean[4:6], 16)
                    data.append([r, g, b])
                except Exception:
                    data.append([0, 0, 0])
    return data

def verify():
    v_data = parse_24b("image_out_24b.hex")
    g_data = parse_24b("expected_out_24b.hex")

    v_img = np.array(v_data, dtype=np.uint8).reshape((HEIGHT, WIDTH, 3))
    g_img = np.array(g_data, dtype=np.uint8).reshape((HEIGHT, WIDTH, 3))

    mse = np.mean((v_img.astype(float) - g_img.astype(float))**2)
    psnr = 20 * np.log10(255.0 / np.sqrt(mse)) if mse > 0 else float('inf')
    ssim_val = ssim(g_img, v_img, channel_axis=2, data_range=255)

    print(f"MSE:  {mse:.4f}")
    print(f"PSNR: {psnr:.2f} dB")
    print(f"SSIM: {ssim_val:.4f}")

    combined = np.hstack((cv2.cvtColor(g_img, cv2.COLOR_RGB2BGR), cv2.cvtColor(v_img, cv2.COLOR_RGB2BGR)))
    cv2.imwrite("comparison.png", combined)

if __name__ == "__main__":
    verify()