//
//  UIViewController+CollectionRefresh.m
//  KKXC_Franchisee
//
//  Created by LL on 16/10/26.
//  Copyright © 2016年 cqingw. All rights reserved.
//

typedef void(^requestBlock)(NSInteger page);

#import <objc/runtime.h>
#import <MJRefresh.h>
#import "UIViewController+CollectionRefresh.h"

static const char collectionPageCountKey;
static const char collectionViewKey;
static const char collectionContentArrKey;

@implementation UIViewController (CollectionRefresh)

- (void)setCollectionRefreshHandle:(requestBlock)actionHandler
{
    NSUInteger _pageCount = 1;
    [self setPageCount:_pageCount];
    
    __weak UICollectionView *_bg_CollectionView = self.bg_CollectionView;
    
    NSUInteger *pageCountWeak = &_pageCount;
    _bg_CollectionView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        //Call this Block When enter the refresh status automatically
        actionHandler(*pageCountWeak=1);
    }];
    
    _bg_CollectionView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        //Call this Block When enter the refresh status automatically
        actionHandler(++*pageCountWeak);
    }];
}

- (void)setNetworkAdd:(NSString *)add paraDic:(NSDictionary *)paraDic pageFiledName:(NSString *)pageFiledName parseDicKeyArr:(NSArray *)dicKeyArr parseModelClass:(Class)modelClass
{
    WeakObj(self)
    
    __weak UICollectionView *_bg_CollectionView = self.bg_CollectionView;
    __weak NSMutableArray *contentArr = self.contentArr;
    
    [self setCollectionRefreshHandle:^(NSInteger page) {
        NSMutableDictionary *paraMutDic = [paraDic mutableCopy];
        if (pageFiledName) {
            [paraMutDic setObject:[NSString stringWithFormat:@"%ld",page] forKey:pageFiledName];
        }
        [KZNetworkEngine postWithUrl:add paraDic:paraMutDic successBlock:^(id jsonObj) {
            if (page==1) {
                //Drop down
                selfWeak.contentArr = [[selfWeak parseJsonDataWithJsonObj:jsonObj dicKeyArr:dicKeyArr parseModelClass:modelClass] mutableCopy];
                [_bg_CollectionView reloadData];
                [_bg_CollectionView.mj_header endRefreshing];
                [selfWeak contentArrDidRefresh:contentArr];
            }
            else
            {
                if (!isNull(jsonObj[@"info"])) {
                    NSArray *appendArr = [selfWeak parseJsonDataWithJsonObj:jsonObj dicKeyArr:dicKeyArr parseModelClass:modelClass];
                    if (appendArr.count) {
                        //还有数据 （追加）
                        [contentArr addObjectsFromArray:appendArr];
                        [_bg_CollectionView reloadData];
                        [selfWeak contentArrDidLoadMoreData:appendArr];
                    }
                    else
                    {
                        //No more data
                        [selfWeak noMoreData];
                    }
                }
                else
                {
                    
                }
                [_bg_CollectionView.mj_footer endRefreshing];
            }
        } failedBlock:^(NSError *error) {
            [_bg_CollectionView.mj_header endRefreshing];
            [_bg_CollectionView.mj_footer endRefreshing];
        }];
    }];
}

//已经重新加载了数据
- (void)contentArrDidRefresh:(NSArray *)newArr
{
    
}

//已经追加了数据
- (void)contentArrDidLoadMoreData:(NSArray *)appendArr
{
    
}

//没有更多数据了
- (void)noMoreData
{
    
}

//静默刷新
- (void)silenceRefresh
{
    
}

//触发下拉刷新
- (void)refreshCollection{
    [self.bg_CollectionView.mj_header beginRefreshing];
}

//解析json数据
- (NSArray *)parseJsonDataWithJsonObj:(id)jsonObj dicKeyArr:(NSArray *)dicKeyArr parseModelClass:(Class)modelClass
{
    id arr = nil;
    int i = 0;
    for (NSString *dicKey in dicKeyArr)
    {
        if (i==0)
        {
            if ([jsonObj isKindOfClass:[NSDictionary class]]) {
                arr = jsonObj[dicKey];
            }
            else if([jsonObj isKindOfClass:[NSArray class]])
            {
                if (((NSArray *)jsonObj).count) {
                    arr = jsonObj[0];
                }
            }
        }
        else
        {
            if ([arr isKindOfClass:[NSDictionary class]]) {
                arr = arr[dicKey];
            }
            else if([arr isKindOfClass:[NSArray class]])
            {
                if (((NSArray *)arr).count) {
                    arr = arr[0];
                }
            }
        }
        i++;
    }
    
    if ([arr isKindOfClass:[NSArray class]]) {
        if (modelClass) {
            return [modelClass mj_objectArrayWithKeyValuesArray:arr];
        } else {
            return arr;
        }
    }
    else if(!isNull(arr))
    {
        if (modelClass) {
            return [modelClass mj_objectArrayWithKeyValuesArray:@[arr]];
        } else {
            return @[arr];
        }
    }
    else
    {
        return @[];
    }
}

#pragma mark - GET && SET

- (NSUInteger)getPageCount{
    return [objc_getAssociatedObject(self, &collectionPageCountKey) unsignedIntegerValue];
}
- (void)setPageCount:(NSUInteger)pageCount{
    objc_setAssociatedObject(self, &collectionPageCountKey, @(pageCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSMutableArray *)contentArr{
    return objc_getAssociatedObject(self, &collectionContentArrKey);
}
- (void)setContentArr:(NSMutableArray *)contentArr{
    objc_setAssociatedObject(self, &collectionContentArrKey, contentArr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (UICollectionView *)bg_CollectionView{
    return objc_getAssociatedObject(self, &collectionViewKey);;
}
- (void)setBg_CollectionView:(UICollectionView *)bg_CollectionView{
    objc_setAssociatedObject(self, &collectionViewKey, bg_CollectionView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
