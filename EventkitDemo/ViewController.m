//
//  ViewController.m
//  EventkitDemo
//
//  Created by 邵广涛 on 2019/4/10.
//  Copyright © 2019年 SGT. All rights reserved.
//

#import "ViewController.h"
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>

@interface ViewController ()<EKEventEditViewDelegate>
@property (nonatomic ,strong)EKEventStore *myEventStore;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSArray *titleArr = @[@"创建",@"查询",@"修改",@"删除",@"调用UI",@"提醒事件"];
    
    for (int i = 0 ; i < titleArr.count; i ++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(100,100 + 70 *i, 100, 50);
        btn.backgroundColor = [UIColor redColor];
        [btn addTarget:self action:@selector(btnClick:) forControlEvents:(UIControlEventTouchUpInside)];
        [btn setTitle:titleArr[i] forState:(UIControlStateNormal)];
        btn.tag = i;
        [self.view addSubview:btn];
    }
}
#pragma mark -- Getter
-(EKEventStore *)myEventStore{
    if (!_myEventStore) {
        _myEventStore = [[EKEventStore alloc] init];
    }
    return _myEventStore;
}

-(void)btnClick:(UIButton *)sender{
    switch (sender.tag) {
        case 0:
            if ([self queryEKEventForIdentifier] == NO) {
                [self createEKEvent];
            }
            break;
        case 1:
            [self queryEKEventForIdentifier];
            break;
        case 2:
            [self updateEKEvent];
            break;
        case 3:
            [self deleteEKEvent];
            break;
        case 4:
            [self openUI];
            break;
        case 5:
            [self addReminderNotify:[NSDate dateWithTimeIntervalSinceNow:60] title:@"测试提醒"];
            break;
        default:
            break;
    }
}
-(void)updateEKEvent{
    EKEvent *event = [self queryEKEventForIdentifier];
    if (event) {
        event.title = @"修改的标题";
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
        NSDate *date = [formatter dateFromString:@"2019-05-13 11:22:33"];
        // 提前一个小时开始
        NSDate *startDate = [NSDate dateWithTimeInterval:-3600 sinceDate:date];
        // 提前一分钟结束
        NSDate *endDate = [NSDate dateWithTimeInterval:60 sinceDate:date];
        
        event.startDate = startDate;
        event.endDate = endDate;
 
        [event setCalendar:[self.myEventStore defaultCalendarForNewEvents]];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error = nil;
            [self.myEventStore saveEvent:event span:EKSpanThisEvent error:&error];
            if (!error) {
                NSLog(@"修改成功");
            }else{
                NSLog(@"添加时间失败:%@",error);
            }
        });
        
    }
}
//根据ID查询事件
-(EKEvent *)queryEKEventForIdentifier{
    // 获取创建的事件ID。
    NSString *identifier = [NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] objectForKey:@"my_eventIdentifier"]];
    EKEvent *event = [self.myEventStore eventWithIdentifier:identifier];
    NSLog(@"查询到的事件 ：%@",event);
    return event;
}
//创建事件
-(void)createEKEvent{
    ///生成事件数据库对象
    EKEventStore *store = self.myEventStore;
    
    if ([self.myEventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
        //申请事件类型权限 EKEntityTypeEvent 时间类型 EKEntityTypeReminder 提醒类型
        [store requestAccessToEntityType:(EKEntityTypeEvent) completion:^(BOOL granted, NSError * _Nullable error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                
                if (error) {
                    NSLog(@"添加失败，，错误了。。。");
                } else if (!granted) {
                    NSLog(@"不允许使用日历，没有权限");
                } else {
                    
                    EKEvent *event = [EKEvent eventWithEventStore:store];
                    event.title = @"这是一个 title";
                    event.location = @"这是一个 location";
                    event.notes = @"这是一个 notes";
                    
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                    
                    NSDate *date = [formatter dateFromString:@"2019-04-13 11:22:33"];
                    
                    // 提前一个小时开始
                    NSDate *startDate = [NSDate dateWithTimeInterval:-3600 sinceDate:date];
                    // 提前一分钟结束
                    NSDate *endDate = [NSDate dateWithTimeInterval:60 sinceDate:date];
                    
                    event.startDate = startDate;
                    event.endDate = endDate;
                    event.allDay = NO;
                    
                    // 添加闹钟结合（开始前多少秒）若为正则是开始后多少秒。
                    EKAlarm *elarm2 = [EKAlarm alarmWithRelativeOffset:-20];
                    [event addAlarm:elarm2];
                    EKAlarm *elarm = [EKAlarm alarmWithRelativeOffset:-10];
                    [event addAlarm:elarm];
                    
                    [event setCalendar:[store defaultCalendarForNewEvents]];
                    
                    NSError *error = nil;
                    [store saveEvent:event span:EKSpanThisEvent error:&error];
                    
                    if (!error) {
                        NSLog(@"添加时间成功");
                        //添加成功后需要保存日历关键字
                        NSString *iden = event.eventIdentifier;
                        // 保存在沙盒，避免重复添加等其他判断
                        [[NSUserDefaults standardUserDefaults] setObject:iden forKey:@"my_eventIdentifier"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }else{
                        NSLog(@"添加时间失败:%@",error);
                    }
                    
                }
            });
        }];
    }
}
//根据ID删除事件
-(void)deleteEKEvent{

    __block EKEvent *event = [self queryEKEventForIdentifier];
    __block BOOL isDeleted = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError *err = nil;
        isDeleted = [self.myEventStore removeEvent:event span:EKSpanThisEvent commit:YES error:&err];
        if (!err && isDeleted) {
            NSLog(@"删除日历成功");
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"my_eventIdentifier"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    });
}
//
-(void)openUI{
    EKEventStore *eventStore = self.myEventStore;
    if([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
        //EKEntityTypeEvent 事件页面
        //EKEntityTypeReminder 提醒页面
        [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted,NSError* error){
            if(!granted){
                dispatch_async(dispatch_get_main_queue(), ^{
                    //TODO: 提示需要权限
                });
            }else{
                
                EKEvent *event = [EKEvent eventWithEventStore:eventStore];
                event.title = @"日历标题";
                
                EKCalendar* calendar;
                calendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:eventStore];
                NSError* error;
                [eventStore saveCalendar:calendar commit:YES error:&error];
                
                EKEventEditViewController *addController = [[EKEventEditViewController alloc] initWithNibName:nil bundle:nil];
                addController.event = event;
                addController.eventStore = eventStore;
                
                [self presentViewController:addController animated:YES completion:nil];
                addController.editViewDelegate = self;
            }
        }];
    }
}
#pragma mark - eventEditDelegates -
- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action{
    if (action ==EKEventEditViewActionCanceled) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    if (action==EKEventEditViewActionSaved) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

//添加提醒通知
-(void)addReminderNotify:(NSDate *)date title:(NSString *)title

{
    
    //申请提醒权限
    [self.myEventStore requestAccessToEntityType:EKEntityTypeReminder completion:^(BOOL granted, NSError * _Nullable error) {
        
        if (granted) {
            //创建一个提醒功能
            
            EKReminder *reminder = [EKReminder reminderWithEventStore:self.myEventStore];
            //标题
            
            reminder.title = title;
            //添加日历
            
            [reminder setCalendar:[self.myEventStore defaultCalendarForNewReminders]];
            
            NSCalendar *cal = [NSCalendar currentCalendar];
            
            [cal setTimeZone:[NSTimeZone systemTimeZone]];
            
            NSInteger flags = NSCalendarUnitYear | NSCalendarUnitMonth |
            
            NSCalendarUnitDay |NSCalendarUnitHour | NSCalendarUnitMinute |
            
            NSCalendarUnitSecond;
            
            NSDateComponents* dateComp = [cal components:flags fromDate:date];
            
            dateComp.timeZone = [NSTimeZone systemTimeZone];
            
            reminder.startDateComponents = dateComp; //开始时间
            
            reminder.dueDateComponents = dateComp; //到期时间
            
            reminder.priority = 1; //优先级
            NSMutableArray *weekArr = [NSMutableArray array];
            NSArray *weeks = @[@1,@2,@3];//1代表周日以此类推
            //  也可以写成NSArray *weekArr = @[@(EKWeekdaySunday),@(EKWeekdayMonday),@(EKWeekdayTuesday)];
            [weeks enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                EKRecurrenceDayOfWeek *daysOfWeek = [EKRecurrenceDayOfWeek dayOfWeek:obj.integerValue];
                [weekArr addObject:daysOfWeek];
            }];
            //创建重复需要用到 EKRecurrenceRule
            //EKRecurrenceFrequencyDaily, 周期为天
            //EKRecurrenceFrequencyWeekly, 周期为周
            //EKRecurrenceFrequencyMonthly, 周期为月
            //EKRecurrenceFrequencyYearly  周期为年
            // EKRecurrenceRule *rule = [[EKRecurrenceRule alloc]initRecurrenceWithFrequency:EKRecurrenceFrequencyWeekly interval:1 daysOfTheWeek:weekArr daysOfTheMonth:nil monthsOfTheYear:nil weeksOfTheYear:nil daysOfTheYear:nil setPositions:nil end:nil];
            
            //每天
            EKRecurrenceRule *rule = [[EKRecurrenceRule alloc] initRecurrenceWithFrequency:(EKRecurrenceFrequencyDaily) interval:1 end:nil];
            [reminder addRecurrenceRule:rule];
            
            EKAlarm *alarm = [EKAlarm alarmWithAbsoluteDate:date]; //添加一个闹钟
            
            [reminder addAlarm:alarm];
            
            NSError *err;
            
            [self.myEventStore saveReminder:reminder commit:YES error:&err];
            
            if (err) {
                
                
            }
            
        }
        
    }];
    
}








@end
