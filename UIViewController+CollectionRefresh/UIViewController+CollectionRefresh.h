//
//  UIViewController+CollectionRefresh.h
//  KKXC_Franchisee
//
//  Created by LL on 16/10/26.
//  Copyright © 2016年 cqingw. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (CollectionRefresh)

/**
 设置需要下拉刷新 上拉加载的collectionView
 */
- (void)setBg_CollectionView:(UICollectionView *)bg_CollectionView;

/**
 设置网络下拉上拉时网络请求的地址和请求参数，页码参数名、以及指定如何解析返回数据
 1.add          : 请求的地址
 2.paraDic      : 请求字典
 3.pageFileNmae : 页码参数名
 4.dicKeyArr    : 解析返回数据的Key数组
 5.modelClass   : 解析的Model类
 */
- (void)setNetworkAdd:(NSString *)add paraDic:(NSDictionary *)paraDic pageFiledName:(NSString *)pageFiledName parseDicKeyArr:(NSArray *)dicKeyArr parseModelClass:(Class)modelClass;

/**
 获取数据源
 如果在 setNetwrokAdd 时指定了modelClass 则 此方法返回的数组由指定的model类对象组成
 如果在 setNetwrokAdd 时modelClass参数传入nil 则 此方法返回的数组是由字典组成
 */
- (NSMutableArray *)contentArr;

/**
 获取表
 */
- (UICollectionView *)bg_CollectionView;

/**
 触发下拉刷新
 */
- (void)refreshCollection;

@end
