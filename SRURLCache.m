//
//  SRURLCache.m
//  SimpResearch
//
//  Created by quentin on 16/1/13.
//  Copyright © 2016年 田家顺. All rights reserved.
//

#import "SRURLCache.h"
#import "SRPathManager.h"

static const NSTimeInterval cacheExpire = 60 * 30;//只缓存大概30分钟，30分钟后过期,默认过期时间，希望通过扩展可以根据不同情况而产生变化

#define kCacheCreateTimeKey @"cacheCreateTime"//缓存记录时间
#define kCacheEndTimeKey @"cacheEndTime"//缓存结束时间
#define kCachePathKey @"cachePath"//缓存对应文件地址

@implementation SRURLCache

+ (SRURLCache *)sharedCache
{
    static SRURLCache *_sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[SRURLCache alloc] init];
    });
    return _sharedInstance;
}

- (NSString *)cachePath
{
    return [SRPathManager appRootDirectory];
}

- (NSString *)cachaePlistPath
{
    return [SRPathManager appRootDirectory];
}

- (void)saveCacheURL
{
    NSString *plistPath = [self cachaePlistPath];
    
    NSDictionary *plistDict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    
    id value = [plistDict objectForKey:_cacheURL.absoluteString];
    if (value == nil) {//不存在此URL链接地址时，则把URL添加到cache plist文件
        
        NSMutableDictionary *saveDict = [NSMutableDictionary dictionaryWithDictionary:plistDict];
        
        NSString *cachePath = [[self cachePath] stringByAppendingPathComponent:_cacheURL.absoluteString];
        
        NSDictionary *cacheDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSDate date], kCacheCreateTimeKey,
                                   [NSDate dateWithTimeIntervalSinceNow:cacheExpire], kCacheEndTimeKey,
                                   cachePath, kCachePathKey,
                                   nil];
        
        [saveDict setObject:cacheDict forKey:_cacheURL.absoluteString];
        [saveDict writeToFile:plistPath atomically:YES];
        
    }
}

@end
