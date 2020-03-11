import pyotp
import qrcode
import base64
import io
import time


data = io.BytesIO(b'awdawd')

x = base64.b32encode(b'awdd')
print(x)
print(str(x))
totp = pyotp.TOTP(x)
uri = totp.provisioning_uri("Muhsigbokz#8821", issuer_name="Drarok Shutdown")
print(uri)
print(totp.now())
exit(0)

# Create qr code instance
qr = qrcode.QRCode(
	version = 1,
	error_correction = qrcode.constants.ERROR_CORRECT_H,
	box_size = 10,
	border = 4,
)

# Add data
qr.add_data(uri)
qr.make(fit=True)

# Create an image from the QR Code instance
img = qr.make_image()


img.save()

# Save it somewhere, change the extension as needed:
# img.save("image.png")
# img.save("image.bmp")
# img.save("image.jpeg")
img.save("image.jpg")





