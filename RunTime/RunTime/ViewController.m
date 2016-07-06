/**
 南峰子技术博客：http://southpeak.github.io/blog/2014/10/25/objective-c-runtime-yun-xing-shi-zhi-lei-yu-dui-xiang/
 runTime的简单学习：
 runTIme库主要做的两件事情
 1、封装：对象用C语言的结构体表示 方法用C函数实现
 2、找出方法的最终执行代码：当程序执行[object doSomething]会根据消息接收者的不同，runTime会根据消息接收者是否能相应消息而做出不同的反应。
 
 OC中的类是由Class类型表示的→objc_class的结构体指针 typedef struct objc_class *Class;
 objc_class {
 isa  一个指向Class类型的isa指针
 supe_class
 name
 version 版本
 info 类信息，供运行期使用的一些位标识
 insstance_size 类的实例变量大小
 objc_ivar_list *ivars 成员变量链表(数组)
 objc_mothod_list *mothodLists 方法链表(数组)
 objc_cache *cache 方法缓存(数组)
 objc_protocol_list *protocols协议链表(数组)
 }
 其实isa指针是指向其类元类metaClass
 
 id类型其实就是一个objc_object的结构体 该结构体中只有一个isa属性，它的存在类似于C++中泛型的一些操作
 当我们像id类型的实例发送消息的时候Runtime库就会根据isa指针找到实例对象所属的类，然在类的方法链表中找到消息对应的selector指向的方法。
 
 objc_cache 方法缓存
 struct objc_cache {
 unsigned int mask  total = mask + 1
 unsigned int occupied
 Method buckets[1]
 };
 
 meta_class 元类
 当我们向一个对象发送消息的时候，runtime会在这个对象所属的这个类的方法列表中查找方法，而向一个类发送消息时，会在这个类的meta_class的方法列表中查找。
 *******meta_class也是一个类，也可以像他发送消息，那么meta_class重的isa最终又会指向谁呢？OC中所以的meta_class的isa都指向基类的meta_class 所以的meta_class都指向NSObject的meta_class。
 */
#import "ViewController.h"
#import <objc/objc-runtime.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    //    [self ex_registerClassPair];
    
    [self ex_registerClassPairq];
}

//void TestMetaClass(id self, SEL _cmd) {
//    NSLog(@"本身的地址:This object is %p",self);
//    NSLog(@"Class is %@,super class is %@",[self class], [self superclass]);
//    Class currentClass = [self class];//本身实例的类
//    for (int i = 0 ; i < 4; i ++) {
//        NSLog(@"Following the isa pointer %d times gives %p",i, currentClass);
//        currentClass = object_getClass(currentClass);
//
//
//    }
//    NSLog(@"NSObject's class is %p", [NSObject class]);
//
//    NSLog(@"NSObject's meta class is %p", object_getClass([NSObject class]));
//
//
//}

//- (void)ex_registerClassPair {
//
//
//
//    Class newClass = objc_allocateClassPair([NSError class], "TestClass", 0);
//
//    class_addMethod(newClass, @selector(testMetaClass), (IMP)TestMetaClass, "v@:");
//
//    objc_registerClassPair(newClass);
//
//
//
//    id instance = [[newClass alloc] initWithDomain:@"some domain" code:0 userInfo:nil];
//
//    [instance performSelector:@selector(testMetaClass)];
//
//}

#pragma mark Runtime中的方法使用
/**
 mark: object_getClass
 eg:  MyClass *p1 = [[MyClass alloc] init];
 [MyClass class];//MyClass为类对象返回其本身，如果是实例时返回类对象。
 Class c1 = object_getClass(p1);
 这样得到的c1就是MyClass类了。
 */
/**
 mark: objc_getClass
 eg Class c1 = objc_getClass("MyClass")
 这样得到的c1就是MyClass类了。
 */

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


void TestMetaClassq(id self, SEL _cmd) {
    
    // self 指实例自身地址 == id instance
    NSLog(@"This objcet is %p", self);
    
    /*
     class 方法实现 return object_getClass(self)
     class方法其实取到传入对象（self）的isa对象而已 self->isa 指向类对象！ %@就会打印类对象的 description 方法
     superclass 方法实现 return [self class]->superclass
     同理 self class 取到类对象 然后取到superclass %@就会打印类对象的 description 方法
     */
    
    NSLog(@"Class is %@, super class is %@", [self class], [self superclass]);
    
    Class currentClass = [self class];// self是实例对象 因此self->isa 取到类对象
    
    
    /*
     现在结构是 NSObject->NSError->TestClass
     */
    for (int i = 0; i < 4; i++) {
        //第0次 currentClass 是TestClass类对象
        //第1次 currentClass 是TestClass 的 metaClass
        //第2次 currentClass 是NSObject 的 metaClass(因为metaClass的isa都是指向基类NSObject的metaClass)
        //第3次 currentClass 是NSObject 的metaClass 是自身。。。。。。正如图所示
        NSLog(@"Following the isa pointer %d times gives %p", i, currentClass);
        
        // 其实是对传入对象->isa
        currentClass = object_getClass(currentClass);
        
    }
    // 图说 NSObject metaClass的superClass 是NSObject类对象！ 测试下
    NSLog(@"NSObject's class is %p (get by NSObject metaClass superClass)",[currentClass superclass]);
    
    // 直接取到NSObject的类对象
    NSLog(@"NSObject's class is %p", [NSObject class]);
    NSLog(@"NSObject's classMin is %p",[[[NSObject alloc] init] class]);
    
    NSLog(@"NSObject's meta class is %p", object_getClass([NSObject class]));
    
}



- (void)ex_registerClassPairq{
    
    /**
     步骤：
     1. objc_allocateClassPair 想要获得metaclass 使用object_getClass(newClass)
     2. 往新增类中添加属性class_addMethod class_addIvar
     3. 最后objc_registerClassPair注册 这样newClass可以使用了
     NOTE:newClass仅仅只是一个类对象 class object 而不是一个类实例！！！
     */
    Class newClass = objc_allocateClassPair([NSError class], "TestClass", 0);
    class_addMethod(newClass, @selector(TestMetaClassq), (IMP)TestMetaClassq, "v@:");
    objc_registerClassPair(newClass);
    
    // 实例化对象 id typedef struct objc_object *id
    // 而类是typedef struct objc_class *Class
    // Class object 同样是一个对象 所以继承自 objc_object
    
    // 接下来实例化一个对象
    id instance = [[newClass alloc]initWithDomain:@"some domain" code:0 userInfo:nil];
    NSLog(@"instance address %p",instance);//等价于self
    [instance performSelector:@selector(TestMetaClassq)];//TestMetaClass是具体实现函数地址 而testMetaClass 只是方法名字
}






@end
