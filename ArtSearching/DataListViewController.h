//
//  DataListViewController.h
//  ArtSearching
//
//  Created by developer on 14-4-17.
//  Copyright (c) 2014年 Duostec. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AFNetworking/AFNetworking.h>
#import "LCYCommon.h"
#import "NetConnect.h"
#import "ZXYProvider.h"
@class ZXYFileOperation;
@class UIFolderTableView;
@class DataAcquisitionViewController;
@interface DataListViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>
{
    IBOutlet UIFolderTableView *dataTableV;
    ZXYProvider *dataProvider;
    NetConnect *netConnect;
    NSArray *arrArtList;
    NSArray *arrArtistsList;
    NSArray *arrGalleryList;
    ZXYFileOperation *fileOperation;
    DataAcquisitionViewController *dataAc;
}
@end
