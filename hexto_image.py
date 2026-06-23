import cv2
import numpy as np
import os

OUTPUT_WIDTH  = 400   
OUTPUT_HEIGHT = 400   
CHANNELS      = 3     

HEX_FILE = "image_out_24b.hex" 
OUTPUT_PNG = "verilog_output_.png" 

def convert_24b_hex_to_image():
    print(f"Reading {HEX_FILE}...")

    if not os.path.exists(HEX_FILE):
        print(f"❌ ERROR: Could not find {HEX_FILE}")
        return

    pixel_data = []
    error_count = 0
    
    with open(HEX_FILE, 'r') as f:
        lines = f.readlines()
        
        for i, line in enumerate(lines):
            clean = line.strip().lower()
            if not clean: continue
            
            if 'x' in clean or 'z' in clean:
                pixel_data.extend([0, 0, 0]) 
                error_count += 1
            else:
                try:

                    clean = clean.zfill(6) 
                    
                    r = int(clean[0:2], 16)
                    g = int(clean[2:4], 16)
                    b = int(clean[4:6], 16)
                    
                    pixel_data.extend([r, g, b])
                except ValueError:
                    print(f"⚠️ Warning: Skipping invalid text at line {i+1}: '{clean}'")
                    pixel_data.extend([0, 0, 0])
                    error_count += 1

    if error_count > 0:
        print(f"⚠️ Replaced {error_count} uninitialized pixels with black.")

    expected_values = OUTPUT_WIDTH * OUTPUT_HEIGHT * CHANNELS
    actual_values = len(pixel_data)
    
    print(f"Extracted {actual_values} color channels.")
    print(f"Expected  {expected_values} color channels ({OUTPUT_WIDTH}x{OUTPUT_HEIGHT} RGB).")

    if actual_values < expected_values:
        print("WARNING: Not enough data! Filling remainder with black.")
        pixel_data += [0] * (expected_values - actual_values)
    elif actual_values > expected_values:
        print("WARNING: Too much data! Truncating extra values.")
        pixel_data = pixel_data[:expected_values]

    image_array = np.array(pixel_data, dtype=np.uint8)
    try:
        reshaped_img_rgb = image_array.reshape((OUTPUT_HEIGHT, OUTPUT_WIDTH, CHANNELS))
    except ValueError as e:
        print(f"❌ CRITICAL ERROR: Could not reshape array. {e}")
        return

    final_bgr_img = cv2.cvtColor(reshaped_img_rgb, cv2.COLOR_RGB2BGR)

    cv2.imwrite(OUTPUT_PNG, final_bgr_img)
    print(f"✅ SUCCESS! Saved output to {OUTPUT_PNG}")
    
    cv2.imshow("Hardware Output", final_bgr_img)
    cv2.waitKey(0)
    cv2.destroyAllWindows()

if __name__ == "__main__":
    convert_24b_hex_to_image()