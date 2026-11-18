// src/TrollFoolsInject.m
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <objc/runtime.h>
#include <objc/message.h>
#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>
#include <substrate.h>
#include <notify.h>

// ====== ĐỊNH NGHĨA CẤU TRÚC TỪ LIBTSM ======
typedef struct {
    void *vtable;
    uint64_t flags;
    uint64_t offset;
    const char *name;
    void *handle;
} TSMContext;

typedef void (*TSMInitFunc)(TSMContext *ctx);
typedef void (*TSMLoadFunc)(const char *path);
typedef void (*TSMUnloadFunc)(void);

// ====== BIẾN TOÀN CỤC ======
static TSMContext *g_tsm_ctx = NULL;
static void *g_original_init = NULL;
static void *g_original_load = NULL;

// ====== HOOK FUNCTIONS ======
static void hooked_TSM_Init(TSMContext *ctx) {
    NSLog(@"[TrollFoolsInject] TSM_Init called");
    NSLog(@"[TrollFoolsInject] Context: %p, Name: %s", ctx, ctx ? ctx->name : "null");
    
    g_tsm_ctx = ctx;
    
    // Thực thi payload chính
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        @try {
            UIAlertController *alert = [UIAlertController 
                alertControllerWithTitle:@"TrollFools" 
                message:@"✅ Dylib đã được tiêm thành công!\nPhiên bản: 1.0.0\niOS: 16.4"
                preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" 
                style:UIAlertActionStyleDefault handler:nil]];
            
            UIWindow *keyWindow = nil;
            if (@available(iOS 13.0, *)) {
                for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                    if (scene.activationState == UISceneActivationStateForegroundActive) {
                        keyWindow = scene.windows.firstObject;
                        break;
                    }
                }
            } else {
                keyWindow = [UIApplication sharedApplication].keyWindow;
            }
            
            if (keyWindow && keyWindow.rootViewController) {
                [keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
            }
        } @catch (NSException *exception) {
            NSLog(@"[TrollFoolsInject] Exception: %@", exception);
        }
    });
    
    // Gọi hàm gốc nếu tồn tại
    if (g_original_init) {
        ((TSMInitFunc)g_original_init)(ctx);
    }
}

static void hooked_TSM_Load(const char *path) {
    NSLog(@"[TrollFoolsInject] TSM_Load called with path: %s", path);
    
    // Thực hiện tải thư viện
    if (g_original_load) {
        ((TSMLoadFunc)g_original_load)(path);
    }
    
    // Payload bổ sung sau khi load
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[TrollFoolsInject] Library loaded successfully");
    });
}

// ====== CONSTRUCTOR ======
__attribute__((constructor))
static void trollfools_inject_init(void) {
    @autoreleasepool {
        NSLog(@"========================================");
        NSLog(@"[TrollFoolsInject] Dylib Loaded");
        NSLog(@"[TrollFoolsInject] iOS Version: %@", [[UIDevice currentDevice] systemVersion]);
        NSLog(@"[TrollFoolsInject] Bundle ID: %@", [[NSBundle mainBundle] bundleIdentifier]);
        NSLog(@"========================================");
        
        // Hook TSM_Init
        MSHookFunction((void *)TSM_Init, (void *)hooked_TSM_Init, &g_original_init);
        
        // Hook TSM_Load nếu có
        void *tsm_load = dlsym(RTLD_DEFAULT, "TSM_Load");
        if (tsm_load) {
            MSHookFunction(tsm_load, (void *)hooked_TSM_Load, &g_original_load);
        }
        
        // Đăng ký notification
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
            object:nil queue:[NSOperationQueue mainQueue]
            usingBlock:^(NSNotification *note) {
                NSLog(@"[TrollFoolsInject] App did finish launching");
                
                // Thực thi payload sau khi app khởi động
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), 
                    dispatch_get_main_queue(), ^{
                    // Payload chính
                    NSLog(@"[TrollFoolsInject] Executing main payload");
                });
            }];
    }
}

// ====== DESTRUCTOR ======
__attribute__((destructor))
static void trollfools_inject_cleanup(void) {
    NSLog(@"[TrollFoolsInject] Dylib unloaded");
}
