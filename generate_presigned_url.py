import boto3

bucket_name = 'photo-uploader-demo-26117ef0'
file_name = 'st.jpg' 

# Create an S3 client
s3 = boto3.client('s3')

try:
    url = s3.generate_presigned_url(
        'put_object',
        Params={
            'Bucket': bucket_name,
            'Key': file_name,
            'ContentType': 'image/jpeg'
        },
        ExpiresIn=300  # URL is valid for 5 minutes
    )

    print("\n✅ Pre-signed URL (valid for 5 minutes):\n")
    print(url)

except Exception as e:
    print(" Error generating pre-signed URL:", e)
