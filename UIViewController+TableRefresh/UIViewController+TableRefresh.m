//
//  UIViewController+TableRefresh.m
//  KKXC_Franchisee
//
//  Created by LL on 16/10/24.
//  Copyright © 2016年 cqingw. All rights reserved.
//

typedef void(^requestBlock)(NSInteger page);

#import <objc/runtime.h>
#import <MJRefresh.h>
#import "UIViewController+TableRefresh.h"

@implementation UIViewController (TableRefresh)

#pragma mark - 设置表

static const char tablePageCountKey;
static const char tableViewKey;
static const char tableContentArrKey;

//block : 约束表的block , block传入nil即可添加默认约束UIEdgeInsetsMake(0, 0, 0, 0)
- (void)setBg_TableViewWithConstraints:(void(^)(MASConstraintMaker *make))block
{
    UITableView *_bg_TableView =[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    [self.view addSubview:_bg_TableView];
    [_bg_TableView mas_makeConstraints: block==nil? ^(MASConstraintMaker *make) {
        make.edges.insets(UIEdgeInsetsMake(0, 0, 0, 0));
    } : block];
    _bg_TableView.delegate = self;
    _bg_TableView.dataSource = self;
    _bg_TableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self setBg_TableView:_bg_TableView];
}

- (void)setTableRefreshHandle:(requestBlock)actionHandler
{
    NSUInteger _pageCount = 1;
    [self setPageCount:_pageCount];
    
    __weak UITableView *_bg_TableView = self.bg_TableView;
    
    NSUInteger *pageCountWeak = &_pageCount;
    _bg_TableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        //Call this Block When enter the refresh status automatically
        actionHandler(*pageCountWeak=1);
    }];
    
    _bg_TableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        //Call this Block When enter the refresh status automatically
        actionHandler(++*pageCountWeak);
    }];
}

- (void)setNetworkAdd:(NSString *)add paraDic:(NSDictionary *)paraDic pageFiledName:(NSString *)pageFiledName parseDicKeyArr:(NSArray *)dicKeyArr parseModelClass:(Class)modelClass
{
    WeakObj(self)
    
    __weak UITableView *_bg_TableView = self.bg_TableView;
    __weak NSMutableArray *contentArr = self.contentArr;
    
    [self setTableRefreshHandle:^(NSInteger page) {
        NSMutableDictionary *paraMutDic = [paraDic mutableCopy];
        if (pageFiledName) {
            [paraMutDic setObject:[NSString stringWithFormat:@"%ld",page] forKey:pageFiledName];
        }
        [KZNetworkEngine postWithUrl:add paraDic:paraMutDic successBlock:^(id jsonObj) {
            if (page==1) {
                //Drop down
                selfWeak.contentArr = [[selfWeak parseJsonDataWithJsonObj:jsonObj dicKeyArr:dicKeyArr parseModelClass:modelClass] mutableCopy];
                [_bg_TableView reloadData];
                [_bg_TableView.mj_header endRefreshing];
                [selfWeak contentArrDidRefresh:contentArr];
            }
            else
            {
                if (!isNull(jsonObj[@"info"])) {
                    NSArray *appendArr = [selfWeak parseJsonDataWithJsonObj:jsonObj dicKeyArr:dicKeyArr parseModelClass:modelClass];
                    if (appendArr.count) {
                        //还有数据 （追加）
                        [contentArr addObjectsFromArray:appendArr];
                        [_bg_TableView reloadData];
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
                [_bg_TableView.mj_footer endRefreshing];
            }
        } failedBlock:^(NSError *error) {
            [_bg_TableView.mj_header endRefreshing];
            [_bg_TableView.mj_footer endRefreshing];
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
- (void)refreshTable{
    [self.bg_TableView.mj_header beginRefreshing];
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
    return [objc_getAssociatedObject(self, &tablePageCountKey) unsignedIntegerValue];
}
- (void)setPageCount:(NSUInteger)pageCount{
    objc_setAssociatedObject(self, &tablePageCountKey, @(pageCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSMutableArray *)contentArr{
    return objc_getAssociatedObject(self, &tableContentArrKey);
}
- (void)setContentArr:(NSMutableArray *)contentArr{
    objc_setAssociatedObject(self, &tableContentArrKey, contentArr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (UITableView *)bg_TableView{
    return objc_getAssociatedObject(self, &tableViewKey);;
}
- (void)setBg_TableView:(UITableView *)bg_TableView{
    objc_setAssociatedObject(self, &tableViewKey, bg_TableView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
