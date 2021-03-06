//
//  ODHomeVC.m
//  OpenDingTalkHelperForiOS
//
//  Created by 李兆祥 on 2019/10/16.
//  Copyright © 2019 ZXLee. All rights reserved.
//  https://github.com/SmileZXLee/OpenDingTalkHelperForiOS

#import "ODHomeVC.h"
#import "ODHistoryVC.h"
#import "ODHelpVC.h"
#import "ODWeekSelectVC.h"
#import "ODHomeCell.h"
#import "ODHomeModel.h"
#import "ODBaseEmptyView.h"
#import "BRDatePickerView.h"
#import "ODHistoryModel.h"
#import "ODWeekSelectModel.h"
#import "UIView+ZXEmptyViewKVO.h"

@interface ODHomeVC ()
@property (weak, nonatomic) IBOutlet ZXTableView *tableView;

@end

@implementation ODHomeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self setupData];
    [self setupNoticeAndNotification];
}
#pragma mark - 初始化操作
#pragma mark 初始化UI
- (void)setupUI{
    self.title = @"钉钉定时打卡助手";
    self.navigationController.navigationBar.translucent = NO;
    self.tableView.backgroundColor = [UIColor colorWithRed:240/255.0 green:240/255.0 blue:240/255.0 alpha:1];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(receiveNotification) name:@"od_receiveNotification" object:nil];
    __weak typeof(self) weakSelf = self;
    UILabel *copyrightLabel = [[UILabel alloc]init];
    copyrightLabel.text = @"- By ZXLee,转载或引用请注明出处 -";
    copyrightLabel.font = [UIFont systemFontOfSize:12];
    copyrightLabel.textAlignment = NSTextAlignmentCenter;
    copyrightLabel.textColor = [UIColor darkGrayColor];
    [self.tableView zx_obsKey:@"contentSize" handler:^(id  _Nonnull newData, id  _Nonnull oldData, id  _Nonnull owner) {
        copyrightLabel.frame = CGRectMake(0, weakSelf.tableView.contentSize.height, weakSelf.tableView.frame.size.width, 30);
    }];
    [self.tableView addSubview:copyrightLabel];
    self.tableView.zx_setCellClassAtIndexPath = ^Class _Nonnull(NSIndexPath * _Nonnull indexPath) {
        return [ODHomeCell class];
    };
    self.tableView.zx_setHeaderViewInSection = ^UIView * _Nonnull(NSInteger section) {
        UIView *headerView = [[UIView alloc]init];
        headerView.backgroundColor = self.tableView.backgroundColor;
        UILabel *headerLabel = [[UILabel alloc]init];
        headerLabel.frame = CGRectMake(15, 0, [UIScreen mainScreen].bounds.size.width - 30, 35);
        headerLabel.font = [UIFont systemFontOfSize:14];
        if(section == 0){
            headerLabel.text = @"状态";
        }else if(section == 1){
            headerLabel.text = @"自动打卡时间";
        }else if(section == 2){
            headerLabel.text = @"功能测试";
        }else if(section == 3){
            headerLabel.text = @"其他";
        }
        [headerView addSubview:headerLabel];
        
        return headerView;
    };
    self.tableView.zx_setHeaderHInSection = ^CGFloat(NSInteger section) {
        return 35;
    };
    self.tableView.zx_didSelectedAtIndexPath = ^(NSIndexPath * _Nonnull indexPath, ODHomeModel * _Nonnull model, id  _Nonnull cell) {
        if([model.title isEqualToString:@"打卡起始时间"] || [model.title isEqualToString:@"打卡结束时间"]){
            [BRDatePickerView showDatePickerWithTitle:[NSString stringWithFormat:@"设置%@",model.title] dateType:BRDatePickerModeTime defaultSelValue:nil resultBlock:^(NSString *selectValue) {
                if([model.title isEqualToString:@"打卡起始时间"]){
                    [ODBaseUtil shareInstance].od_startTime = selectValue;
                    [weakSelf updateTimeStartModel];
                }else{
                    [ODBaseUtil shareInstance].od_endTime = selectValue;
                    [weakSelf updateTimeEndModel];
                }
            }];
        }else if([model.title isEqualToString:@"下次打卡时间"]){
            [weakSelf updateTimeCurrentModel];
        }else if([model.title isEqualToString:@"测试打开钉钉"]){
            [weakSelf openDingTalk];
        }else if([model.title isEqualToString:@"开源地址"]){
            [UIPasteboard generalPasteboard].string = @"https://github.com/SmileZXLee/OpenDingTalkHelperForiOS";
            [ODBaseUtil showToast:@"已复制到剪切板"];
        }else if([model.detail isEqualToString:@"未开启推送权限"]){
            [ODBaseUtil openSetting];
        }else if([model.title isEqualToString:@"自动打卡记录"]){
            ODHistoryVC *historyVC = [[ODHistoryVC alloc]init];
            [weakSelf.navigationController pushViewController:historyVC animated:YES];
        }else if([model.title isEqualToString:@"星期"]){
            ODWeekSelectVC *weekSelectVC = [[ODWeekSelectVC alloc]init];
            [weakSelf.navigationController pushViewController:weekSelectVC animated:YES];
            weekSelectVC.savedBlock = ^{
                [weakSelf updateWeekModel];
            };
        }else if([model.title isEqualToString:@"使用说明(必看)"]){
            ODHelpVC *helpVC = [[ODHelpVC alloc]init];
            [weakSelf.navigationController pushViewController:helpVC animated:YES];
        }
    };
}

#pragma mark 初始化数据
- (void)setupData{
    ODHomeModel *statusModel = [[ODHomeModel alloc]init];
    statusModel.title = @"就绪状态";
    statusModel.detail = @"已就绪";
    
    ODHomeModel *timeStartModel = [[ODHomeModel alloc]init];
    timeStartModel.title = @"打卡起始时间";
    timeStartModel.detail = @"点击设置";
    
    ODHomeModel *timeEndModel = [[ODHomeModel alloc]init];
    timeEndModel.title = @"打卡结束时间";
    timeEndModel.detail = @"点击设置";
    
    ODHomeModel *currentTimeModel = [[ODHomeModel alloc]init];
    currentTimeModel.title = @"下次打卡时间";
    currentTimeModel.detail = @"在设定范围内随机";
    
    ODHomeModel *weekModel = [[ODHomeModel alloc]init];
    weekModel.title = @"星期";
    weekModel.detail = @"每天";
    
    ODHomeModel *jumpTestModel = [[ODHomeModel alloc]init];
    jumpTestModel.title = @"测试打开钉钉";
    
    ODHomeModel *recordsModel = [[ODHomeModel alloc]init];
    recordsModel.title = @"自动打卡记录";
    
    ODHomeModel *helpModel = [[ODHomeModel alloc]init];
    helpModel.title = @"使用说明(必看)";
    
    ODHomeModel *aboutModel = [[ODHomeModel alloc]init];
    aboutModel.title = @"开源地址";
    aboutModel.detail = @"点击复制";
    
    self.tableView.zxDatas = [@[@[statusModel],
                                
                               @[timeStartModel,timeEndModel,currentTimeModel,weekModel],
                                @[jumpTestModel],
                                @[recordsModel,helpModel,aboutModel],
                                
                               ]mutableCopy];
    [self updateTimeStartModel];
    [self updateTimeEndModel];
    [self updateWeekModel];
}

#pragma mark 设置EmptyView
- (void)setupEmptyView{
    [self.view zx_setEmptyView:@"ODBaseEmptyView" isFull:YES clickedTarget:self selector:@selector(openDingTalkAndAskForNotification)];
    self.view.zx_emptyContentView.zx_type = ODEmptyViewTypeAttension;
    [self.view.zx_emptyContentView zx_show];
}

#pragma mark 初始化EmptyView
- (void)setupNoticeAndNotification{
    BOOL od_noticed = [ZXDataStoreCache readBoolForKey:@"od_noticed"];
    if(!od_noticed){
        [self setupEmptyView];
        [ZXDataStoreCache saveBool:YES forKey:@"od_noticed"];
    }
}

#pragma mark - Private
#pragma mark 打开钉钉并且请求通知权限
- (void)openDingTalkAndAskForNotification{
    [self openDingTalk];
    [ODBaseUtil askForUserNotification];
}

#pragma mark 应用进入前台
- (void)appWillEnterForeground{
    [self updateStatusModel];
    [self updateTimeCurrentModel];
}

#pragma mark 打开钉钉
- (BOOL)openDingTalk{
    NSString *schemeUrlStr = @"dingtalk://";
    NSURL *schemeUrl = [NSURL URLWithString:schemeUrlStr];
    if([[UIApplication sharedApplication]canOpenURL:schemeUrl]){
        [[UIApplication sharedApplication] openURL:schemeUrl];
        return YES;
    }
    [ODBaseUtil showToast:@"请安装钉钉"];
    return NO;
}

#pragma mark 判断是否可以打开钉钉
- (BOOL)canOpenDingTalk{
    NSString *schemeUrlStr = @"dingtalk://";
    NSURL *schemeUrl = [NSURL URLWithString:schemeUrlStr];
    return [[UIApplication sharedApplication]canOpenURL:schemeUrl];
}

#pragma mark 更新“就绪状态”
- (void)updateStatusModel{
    BOOL installDingtalk = [self canOpenDingTalk];
    __block ODHomeModel *statusModel = self.tableView.zxDatas[0][0];
    if(!installDingtalk){
        statusModel.detail = @"未安装钉钉";
    }else{
        NSString *startTime = [ODBaseUtil shareInstance].od_startTime;
         NSString *endTime = [ODBaseUtil shareInstance].od_endTime;
        if(!startTime.length){
            statusModel.detail = @"未设置起始时间";
        }else if(!endTime.length){
            statusModel.detail = @"未设置结束时间";
        }else{
            statusModel.detail = @"已就绪";
        }
    }
    if([statusModel.detail isEqualToString:@"已就绪"]){
        [ODBaseUtil checkUserNotificationEnableCallback:^(BOOL enable) {
            if(!enable){
                statusModel.detail = @"未开启推送权限";
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:0];
            }
        }];
    }
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:0];
}

#pragma mark 更新“打卡开始时间”
- (void)updateTimeStartModel{
    NSString *startTime = [ODBaseUtil shareInstance].od_startTime;
    ODHomeModel *timeStartModel = self.tableView.zxDatas[1][0];
    timeStartModel.detail = startTime;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:0];
    [self updateTimeCurrentModel];
    [self updateStatusModel];
}

#pragma mark 更新“打卡结束时间”
- (void)updateTimeEndModel{
    NSString *endTime = [ODBaseUtil shareInstance].od_endTime;
    ODHomeModel *timeEndModel = self.tableView.zxDatas[1][1];
    timeEndModel.detail = endTime;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:0];
    [self updateTimeCurrentModel];
    [self updateStatusModel];
}

#pragma mark 更新“下次打卡时间”
- (void)updateTimeCurrentModel{
    NSString *startTime = [ODBaseUtil shareInstance].od_startTime;
    NSString *endTime = [ODBaseUtil shareInstance].od_endTime;
    ODHomeModel *timeCurrentModel = self.tableView.zxDatas[1][2];
    if(startTime.length && endTime.length){
        long startMin = [ODBaseUtil getTotalMinsHm:startTime];
        long endMin = [ODBaseUtil getTotalMinsHm:endTime];
        long currentMin= [ODBaseUtil getRandomNumber:startMin to: endMin - 1];
        timeCurrentModel.detail = [ODBaseUtil getHmWithTotalMinutes:currentMin];
        timeCurrentModel.detail = [ODBaseUtil addLocalNoticeNextHm:timeCurrentModel.detail];
        
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:1]] withRowAnimation:0];
    }else{
        [ODBaseUtil showToast:@"请设置起始与结束时间"];
    }
}

#pragma mark 更新“星期”
- (void)updateWeekModel{
    ODHomeModel *weekModel = self.tableView.zxDatas[1][3];
    NSString *weekdetail = @"";
    NSArray *selectedArray = [ODWeekSelectModel zx_dbQuaryWhere:@""];
    if(!selectedArray)return;
    for (ODWeekSelectModel *selectModel in selectedArray) {
        if(selectModel.selected){
            weekdetail = [weekdetail stringByAppendingString:[NSString stringWithFormat:@"%d、",selectModel.number]];
        }
    }
    if(weekdetail.length){
        weekdetail = [weekdetail substringToIndex:weekdetail.length - 1];
    }else{
        weekdetail = @"永不";
    }
    weekModel.detail = weekdetail;
    if([weekModel.detail isEqualToString:@"1、2、3、4、5、6、7"]){
        weekModel.detail = @"每天";
    }
    if([weekModel.detail isEqualToString:@"1、2、3、4、5"]){
        weekModel.detail = @"每工作日";
    }
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:1]] withRowAnimation:0];
    [self updateTimeCurrentModel];
    
}

#pragma mark 接收到本地推送
- (void)receiveNotification{
    BOOL success = [self openDingTalk];
    ODHistoryModel *historyModel = [[ODHistoryModel alloc]init];
    historyModel.time = [ODBaseUtil getNowFullStr];
    historyModel.status = success ? @"成功" : @"失败";
    [historyModel zx_dbSave];
}
@end
