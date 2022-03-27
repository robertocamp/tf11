### KMS key
- KMS is replacing the term customer master key (CMK) with KMS key
  + symmetric KMS key
   - contain a 256-bit symmetric key that never leaves KMS unencrypted
   - To use the KMS key, you must call KMS
   - You can use a symmetric KMS key to encrypt and decrypt small amounts of data, but they are typically used to generate data keys and data keys pairs
  + asymmetric KMS key
   - can contain an RSA key pair or an Elliptic Curve (ECC) key pair
   - The private key in an asymmetric KMS key never leaves KMS unencrypted
   - However, you can use the GetPublicKey operation to download the public key so it can be used outside of KMS
   - KMS keys with RSA key pairs can be used to encrypt or decrypt data or sign and verify messages (but not both)
- AWS CLI for KMS
  + aws kms create-key 
- AWS console instructions: 
  + key name: <NAME OF KEY>
  + key usage permissions:
    - AWSServiceRoleForAmazonEKS
    - AWSServiceRoleForAmazonEKSNodegroup
    - AWSServiceRoleForElasticLoadBalancing
    - AWSServiceRoleForAutoScaling
