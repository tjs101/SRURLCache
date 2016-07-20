//
//  SRURLCache.m
//  SimpResearch
//
//  Created by quentin on 16/1/13.
//  Copyright © 2016年 上海美市科技有限公司. All rights reserved.
//

#import "SRURLCache.h"
#import "SRPathManager.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>

static const NSTimeInterval cacheExpire = 60 * 60 * 24 * 7;//只缓存大概7天时间(默认过期时间)，希望通过扩展可以根据不同情况而产生变化

#define kCacheCreateTimeKey     @"cacheCreateTime"//缓存记录时间
#define kCacheEndTimeKey        @"cacheEndTime"//缓存结束时间
#define kCachePathKey           @"cachePath"//缓存对应文件

#define kCachePlistPath         @"cachePlist.plist"

@interface SRURLCache ()

{
    NSMutableDictionary  *_cacheDict;
    
    BOOL                  _needSaveCache;//是否可以保存数据
}

@property (nonatomic, copy) NSString *cacheKey;/**<默认为URL+参数*/

@property (nonatomic, strong) NSURL *cacheURL;/**<缓存URL*/
@property (nonatomic, strong) NSDictionary *parameter;/**<参数*/

@end

@implementation SRURLCache
@synthesize cacheKey;
@synthesize cacheExpireTime;

+ (SRURLCache *)sharedCache
{
    static SRURLCache *_sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[SRURLCache alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.cacheExpireTime = cacheExpire;
        
        NSString *plistPath = [self cachePlistPath];
        NSLog(@"plistPath %@", plistPath);
        _cacheDict = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    }
    return self;
}

- (NSString *)cacheKey
{
    if (_cacheURL && _parameter) {
        return [self sha256:[NSString stringWithFormat:@"%@%@BXWkx5Mv$8aQ0E", _cacheURL.absoluteString, _parameter.description]];
    }
    return _cacheURL.absoluteString;
}

#pragma mark - 缓存文件根目录
- (NSString *)cacheFileRootPath
{
    return [[SRPathManager uidRootDirectory] stringByAppendingPathComponent:kCachePathKey];
}

#pragma mark - 缓存
- (NSString *)cachePlistPath
{
    return [[SRPathManager uidRootDirectory] stringByAppendingPathComponent:kCachePlistPath];
}

#pragma mark - 缓存文件地址
- (NSString *)cacheFilePath
{
    NSString *path = [self cacheFileRootPath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:NULL error:NULL];
    }

    return [path stringByAppendingPathComponent:self.cacheKey];
}

#pragma mark - 初始化数据

- (BOOL)cacheWithURL:(NSURL *)cacheURL parameter:(NSDictionary *)parameter
{
    if (cacheURL) {
        _cacheURL = cacheURL;
    }
    
    if (parameter) {
        _parameter = [NSDictionary dictionaryWithDictionary:parameter];
    }
    else {
        _parameter = [NSDictionary dictionaryWithObject:[[self class] description] forKey:@"description"];
    }
    
    return _cacheURL != nil;
}

#pragma mark - 保存数据

- (void)saveCacheWithURL:(NSURL *)cacheURL parameter:(NSDictionary *)parameter cacheData:(NSDictionary *)cacheData
{
    if ([self cacheWithURL:cacheURL parameter:parameter]) {
        [self saveCachePlist];
        [self saveCacheData:cacheData];
    }
    else {
        NSLog(@"输入url为空，不进行保存数据");
    }
}

#pragma mark - 保存缓存相关数据到字典
- (void)saveCachePlist
{
    NSDictionary *cacheDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSDate date], kCacheCreateTimeKey,
                                [NSDate dateWithTimeIntervalSinceNow:self.cacheExpireTime], kCacheEndTimeKey,
                                self.cacheKey, kCachePathKey,
                                nil];
    [_cacheDict setObject:cacheDict forKey:self.cacheKey];
    
    [self afterDelaySaveCachePlist];

}

- (void)afterDelaySaveCachePlist
{
    if (_needSaveCache) {
        return;
    }
    _needSaveCache = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *plistPath = [self cachePlistPath];

        if (!_needSaveCache) {
            return;
        }
        [_cacheDict writeToFile:plistPath atomically:YES];
        _needSaveCache = NO;
    });
}

#pragma mark - 保存数据
- (void)saveCacheData:(NSDictionary *)saveData
{
    NSString *cachePath = [self cacheFilePath];

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:saveData];
    
    if (data) {
        BOOL success = [data writeToFile:cachePath atomically:YES];
        
        if (!success) {
            NSLog(@"数据保存失败");
        }
    }
    else {
        NSLog(@"data数据为空");
    }
}

#pragma mark - 获取数据

- (id)cacheDataWithURL:(NSURL *)cacheURL parameter:(NSDictionary *)parameter
{
    if ([self cacheWithURL:cacheURL parameter:parameter]) {

        NSDictionary *cacheDict = [_cacheDict objectForKey:self.cacheKey];
        if (cacheDict) {

            NSDate *cacheDate = [cacheDict objectForKey:kCacheEndTimeKey];
            NSString *cachePath = [[self cacheFileRootPath] stringByAppendingPathComponent:[cacheDict objectForKey:kCachePathKey]];
            
            if ([[NSDate date] timeIntervalSinceDate:cacheDate] > 0) {
                NSLog(@"缓存过期");
            }
            else {
                NSLog(@"缓存未过期");
                NSFileManager *fileManager = [NSFileManager defaultManager];
                
                if ([fileManager fileExistsAtPath:cachePath]) {
                    return [NSKeyedUnarchiver unarchiveObjectWithFile:cachePath];
                }
                else {
                    NSLog(@"保存文件不存在");
                }
            }
        }
    }

    return nil;
}

#pragma mark - 清空过期数据
- (void)clearOutdateData
{
    NSLog(@"cacheDict %@", _cacheDict);
    
    NSDate *currentDate = [NSDate date];
    
    NSMutableArray *removeKeys = [NSMutableArray array];
    for (NSString *key in [_cacheDict allKeys]) {
        
        NSDictionary *cacheDict = [_cacheDict objectForKey:key];

        NSDate *cacheEndTime = [cacheDict objectForKey:kCacheEndTimeKey];

        if ([currentDate timeIntervalSinceDate:cacheEndTime] > 0) {
            NSLog(@"数据过期了 %@", @([currentDate timeIntervalSinceDate:cacheEndTime]));
            NSString *cachePath = [[self cacheFileRootPath] stringByAppendingPathComponent:[cacheDict objectForKey:kCachePathKey]];
            
            [[NSFileManager defaultManager] removeItemAtPath:cachePath error:NULL];
            
            [removeKeys addObject:key];
        }
    }

    [_cacheDict removeObjectsForKeys:removeKeys];
    [_cacheDict writeToFile:[self cachePlistPath] atomically:YES];
}

#pragma mark - sha256

- (NSString*)sha256:(NSString *)key
{
    const char *cstr = [key cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:key.length];
    
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    
    CC_SHA256(data.bytes, (int)data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
}

@end
