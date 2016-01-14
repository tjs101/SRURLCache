//
//  SRURLCache.h
//  SimpResearch
//  根据URL自动缓存数据到本地
//  Created by quentin on 16/1/13.
//  Copyright © 2016年 田家顺. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SRURLCache : NSObject

+ (SRURLCache *)sharedCache;

@property (nonatomic, strong) NSURL *cacheURL;/**<缓存URL*/
@property (nonatomic, strong) NSDictionary *parameter;/**<参数*/

@end
