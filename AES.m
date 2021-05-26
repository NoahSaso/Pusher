#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>

/*
@enum       CCCryptorStatus
@abstract   Return values from CommonCryptor operations.

@constant   kCCSuccess          Operation completed normally.
@constant   kCCParamError       Illegal parameter value.
@constant   kCCBufferTooSmall   Insufficent buffer provided for specified 
																operation.
@constant   kCCMemoryFailure    Memory allocation failure. 
@constant   kCCAlignmentError   Input size was not aligned properly. 
@constant   kCCDecodeError      Input data did not decode or decrypt 
																properly.
@constant   kCCUnimplemented    Function not implemented for the current 
																algorithm.
enum {
    kCCSuccess          = 0,
    kCCParamError       = -4300,
    kCCBufferTooSmall   = -4301,
    kCCMemoryFailure    = -4302,
    kCCAlignmentError   = -4303,
    kCCDecodeError      = -4304,
    kCCUnimplemented    = -4305
};
typedef int32_t CCCryptorStatus;
*/

@implementation NSData (AES256)

- (NSDictionary *)AES256EncryptWithKey:(NSString *)key iv:(char*)iv {
	// 'key' should be 32 bytes for AES256, will be null-padded otherwise
	char keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
	bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
	
	// fetch key data
	[key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
	
	NSUInteger dataLength = [self length];
	
	//See the doc: For block ciphers, the output size will always be less than or 
	//equal to the input size plus the size of one block.
	//That's why we need to add the size of one block here
	size_t bufferSize = dataLength + kCCBlockSizeAES128;
	void *buffer = malloc(bufferSize);
	
	size_t numBytesEncrypted = 0;
	CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
									 keyPtr, kCCKeySizeAES256,
									 iv /* initialization vector (optional) */,
									 [self bytes], dataLength, /* input */
									 buffer, bufferSize, /* output */
									 &numBytesEncrypted);
	if (cryptStatus == kCCSuccess) {
		//the returned NSData takes ownership of the buffer and will free it on deallocation
		return @{ @"data": [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted] };
	}

	free(buffer); //free the buffer;
	return @{ @"error": @(cryptStatus) };
}

- (NSDictionary *)AES256DecryptWithKey:(NSString *)key {
	// 'key' should be 32 bytes for AES256, will be null-padded otherwise
	char keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
	bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
	
	// fetch key data
	[key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
	
	NSUInteger dataLength = [self length];
	
	//See the doc: For block ciphers, the output size will always be less than or 
	//equal to the input size plus the size of one block.
	//That's why we need to add the size of one block here
	size_t bufferSize = dataLength + kCCBlockSizeAES128;
	void *buffer = malloc(bufferSize);
	
	size_t numBytesDecrypted = 0;
	CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
									 keyPtr, kCCKeySizeAES256,
									 NULL /* initialization vector (optional) */,
									 [self bytes], dataLength, /* input */
									 buffer, bufferSize, /* output */
									 &numBytesDecrypted);
	
	if (cryptStatus == kCCSuccess) {
		//the returned NSData takes ownership of the buffer and will free it on deallocation
		return @{ @"data": [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted] };
	}
	
	free(buffer); //free the buffer;
	return @{ @"error": @(cryptStatus) };
}

@end
