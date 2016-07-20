//
//  SRURLCache.h
//  SimpResearch
//  根据URL自动缓存数据到本地
//  Created by quentin on 16/1/13.
//  Copyright © 2016年 上海美市科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRURLCache : NSObject

+ (SRURLCache *)sharedCache;

@property (nonatomic, assign) NSTimeInterval cacheExpireTime;/**<过期时间，当前默认为7天时间*/

- (void)saveCacheWithURL:(NSURL *)cacheURL parameter:(NSDictionary *)parameter cacheData:(NSDictionary *)cacheData;//保存数据
- (id)cacheDataWithURL:(NSURL *)cacheURL parameter:(NSDictionary *)parameter;//获取数据

- (void)clearOutdateData;//清空过期缓存数据

@end
