/*
 *  System Versioning Preprocessor Macros
 */

// Already exists, taken from https://gist.github.com/alex-cellcity/998472
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

// Mine
#define SYSTEM_VERSION_IS_IN_RANGE(v, w)			(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) && SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(w))
#define SYSTEM_VERSION_NOT_IN_RANGE(v, w)			(!SYSTEM_VERSION_IS_IN_RANGE(v, w))
#define SYSTEM_VERSION_NOT_EQUAL_TO(v)				(!SYSTEM_VERSION_EQUAL_TO(v))

/* Usage

 * Checks if version is any iOS 8 version. (Use .9.9 to include ALL of Apple's future releases of this version)
if(SYSTEM_VERSION_IS_IN_RANGE(@"8.0", @"8.9.9")) {
    ...
}

 * Checks if version is below 7.1
if (SYSTEM_VERSION_LESS_THAN(@"7.1")) {
    ...
}

 * Checks if version is 6.0.2 or higher
if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0.2")) {
    ...
}

 * Checks if version is anything except 8.0, 8.0.1, 8.0.2, 8.1, and 8.1.1 (anything inside range of 8.0 - 8.1.1)
if (SYSTEM_VERSION_NOT_IN_RANGE(@"8.0", @"8.1.1")) {
    ...
}

*/
