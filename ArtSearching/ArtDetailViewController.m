//
//  ArtDetailViewController.m
//  ArtSearching
//
//  Created by developer on 14-4-21.
//  Copyright (c) 2014年 Duostec. All rights reserved.
//

#import "ArtDetailViewController.h"
#import "ZXYProvider.h"
#import "ArtDetail.h"
#import "CommentDetail.h"
#import "ArtDetailContentArtCell.h"

#import "UserCommentCell.h"
#import "NetConnect.h"
#import "ZXYFileOperation.h"
#import "ShowBigImageViewController.h"
@interface ArtDetailViewController ()
{
    NSString *_workID;
    NSString *_imageURL;
    NSArray  *commentArr;
    ZXYProvider *dataProvider;
    ArtDetail   *artDetail;
    NetConnect *netConnect;
    ZXYFileOperation *fileOperate;
    NSData *imageData;
    UIImage *currentImage;
}
@property (nonatomic,strong)NSString *workID;
@property (nonatomic,strong)NSString *imageURL;
@end

@implementation ArtDetailViewController
@synthesize workID = _workID;
@synthesize imageURL = _imageURL;

- (id)initWithWorkID:(NSString *)userid andWorkUrl:(NSString *)workUrl withBundleName:(NSString *)bundleName
{
    self = [super initWithNibName:bundleName bundle:nil];
    if(self)
    {
        self.workID = userid;
        self.imageURL = workUrl;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(0, 0, 45, 45);
    [backBtn setImage:[UIImage imageNamed:@"back_icon.png"] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backViewBtn:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBtn = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = leftBtn;
    NSNotificationCenter *noti = [NSNotificationCenter defaultCenter];
    [noti addObserver:self selector:@selector(refreshCurrentTable:) name:@"artDetailNotification" object:nil];
       //[netConnect obtainStartArtDetailInfo:self.workID];
    
    fileOperate = [ZXYFileOperation sharedSelf];
    NSString *filePath = [fileOperate findArtOfStartByUrlBig:self.imageURL];
    if(![fileOperate fileExistsAtPath:filePath])
    {
        [self performSelectorInBackground:@selector(downLoadImage) withObject:nil];
    }
    else
    {
        imageData = [NSData dataWithContentsOfFile:filePath];
        currentImage = [UIImage imageWithData:imageData];
    }
    dataProvider = [ZXYProvider sharedInstance];
    netConnect = [NetConnect sharedSelf];
    [NSThread detachNewThreadSelector:@selector(obtainStartArtDetailInfo:) toTarget:netConnect withObject:self.workID];
    
    NSArray *allDetails = [dataProvider readCoreDataFromDB:@"ArtDetail" withContent:self.workID andKey:@"id_Art"];
    commentArr   = [dataProvider readCoreDataFromDB:@"CommentDetail" withContent:self.workID andKey:@"workid" orderBy:@"comdate" isDes:NO];
    
    if(allDetails.count)
    {
        artDetail = [allDetails objectAtIndex:0];
    }
    [contentTableView reloadData];
    // Do any additional setup after loading the view from its nib.
}

- (void)downLoadImage
{
    NSString *urlString = [[NSString stringWithFormat:@"%@%@",imageHost,self.imageURL] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *urlRequest = [[NSURLRequest alloc]initWithURL:url];
    AFHTTPRequestOperation *request = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    request.responseSerializer = [AFImageResponseSerializer serializer];
    [request setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        UIImage *downImg = (UIImage *)responseObject;
        NSData *imageDatas = UIImageJPEGRepresentation(downImg, 1);
        imageData = imageDatas;
        currentImage = [UIImage imageWithData:imageData];
        [imageData writeToFile:[fileOperate findArtOfStartByUrlBig:self.imageURL] atomically:YES];
        [self performSelectorOnMainThread:@selector(refreshCurrentTable:) withObject:nil waitUntilDone:YES];
        NSLog(@"success");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"error is %@",error);
    }];
    
    [request start];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

- (void)refreshCurrentTable:(NSNotification *)noti
{
    if(!self)
    {
        return;
    }
    NSArray *allDetails = [dataProvider readCoreDataFromDB:@"ArtDetail" withContent:self.workID andKey:@"id_Art"];
    if(allDetails.count)
    {
        artDetail = [allDetails objectAtIndex:0];
    }

    commentArr = [dataProvider readCoreDataFromDB:@"CommentDetail" withContent:self.workID andKey:@"workid" orderBy:@"comdate" isDes:NO];
       [contentTableView reloadData];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"artDetailNotification" object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0)
    {
        return 1;
    }
    else if(section == 1)
    {
        return 1;
    }
    else
    {
        return commentArr.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0)
    {
        return 218;
    }
    else if(indexPath.section == 1)
    {
        return 279;
    }
    else
    {
        return 101;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *imageCellIdentifier = @"imageCellIdentifier";
    static NSString *artDetailCellIdentifier = @"artDetailCellIdentifier";
    static NSString *userCommentCellIdentifier = @"userCommentCellIdentifier";
    UITableViewCell *cell ;
    if(indexPath.section == 0)
    {
        ImageViewForCellTableViewCell *imageCell = [tableView dequeueReusableCellWithIdentifier:imageCellIdentifier];
        
        if(imageCell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([ImageViewForCellTableViewCell class]) owner:self options:nil];
            for(id oneObject in nib)
            {
                if([oneObject isKindOfClass:[ImageViewForCellTableViewCell class]])
                {
                    imageCell = (ImageViewForCellTableViewCell *)oneObject;
                    
                }
            }
            
        }
        if(imageData)
        {
            imageCell.bigImageView.image = currentImage;
        }
        imageCell.delegate = self;
        cell = imageCell;
    }
    else if(indexPath.section == 1)
    {
        ArtDetailContentArtCell *imageCell = [tableView dequeueReusableCellWithIdentifier:artDetailCellIdentifier];
        if(imageCell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([ArtDetailContentArtCell class]) owner:self options:nil];
            for(id oneObject in nib)
            {
                if([oneObject isKindOfClass:[ArtDetailContentArtCell class]])
                {
                    imageCell = (ArtDetailContentArtCell *)oneObject;
                }
            }
        }
        if(artDetail)
        {
            imageCell.authodLbl.text = artDetail.author;
            imageCell.titleLbl.text  = artDetail.workName;
            imageCell.sizeLbl.text   = [NSString stringWithFormat:@"%@",artDetail.workSize];
            imageCell.typeLbl.text   = artDetail.workCategory;
            imageCell.concerdNum.text = [NSString stringWithFormat:@"%d次关注",artDetail.beStoreTime.intValue];
            imageCell.commentNum.text = [NSString stringWithFormat:@"这张画已经被说了%d次",artDetail.beCommentTime.intValue];
        }
        cell = imageCell;
    }
    else
    {
        UserCommentCell *imageCell = [tableView dequeueReusableCellWithIdentifier:userCommentCellIdentifier];
        CommentDetail *comment = [commentArr objectAtIndex:indexPath.row];
        if(imageCell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([UserCommentCell class]) owner:self options:nil];
            for(id oneObject in nib)
            {
                if([oneObject isKindOfClass:[UserCommentCell class]])
                {
                    imageCell = (UserCommentCell *)oneObject;
                }
            }
        }
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *timeString = [dateFormatter stringFromDate:comment.comdate];
        imageCell.commentDate.text = timeString;
        
        imageCell.commetContent.text = comment.comtxt;
        cell = imageCell;
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0 || indexPath.section ==1)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

- (void)showBigImageDelegate
{
    if(imageData)
    {
        ShowBigImageViewController *bigImage = [[ShowBigImageViewController alloc] initWithImageData:imageData];
        bigImage.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        UINavigationController *navigation =[ [UINavigationController alloc]initWithRootViewController:bigImage];
        [self presentViewController:navigation animated:YES completion:^{
            
        }];
        
    }
    else
    {
        return;
    }
}

- (void)backViewBtn:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}
@end
