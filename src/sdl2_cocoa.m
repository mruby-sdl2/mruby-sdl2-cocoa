#include "sdl2_cocoa.h"

#include "sdl2.h"

#include "mruby.h"
#include "mruby/value.h"
#include "mruby/string.h"
#include "mruby/data.h"

// #include <SDL2/SDL_video.h>
#include "sdl2_video.h"
#include <SDL2/SDL_syswm.h>
#import <Cocoa/Cocoa.h>

static mrb_value mrb_sdl2_cocoa_change_transparency(mrb_state *mrb, mrb_value self)
{
  SDL_Window *window = mrb_sdl2_video_window_get_ptr(mrb, self);
  SDL_SysWMinfo info;
  if( SDL_GetWindowWMInfo(window, &info) == false ) {
    printf("SDL_GetWindowWMInfo from %d FAILED.\n", window);
    return mrb_nil_value();
  }
  NSWindow *nswindow = info.info.cocoa.window;

  @autoreleasepool {
    NSLog(@"nswindow is %@\n",nswindow);
    NSLog(@"contentView is %@\n",[nswindow contentView]);
    [nswindow setOpaque:NO];
    [nswindow setBackgroundColor:[NSColor clearColor]];
    return self;
  }
}

static mrb_value mrb_sdl2_cocoa_change_transparency_gl_context(mrb_state *mrb, mrb_value self)
{ @autoreleasepool {
  NSOpenGLContext* context = [NSOpenGLContext currentContext];
  NSLog(@"NSOpenGLContext %@\n", context);
  GLint opaque = 0;
  [context setValues:&opaque forParameter:NSOpenGLCPSurfaceOpacity];
  return mrb_nil_value();
} }

void mrb_mruby_sdl2_cocoa_gem_init(mrb_state *mrb) {
  int arena_size;

  struct RClass *mod_Video;
  struct RClass *class_Window;

  mod_Video = mrb_module_get_under(mrb, mod_SDL2,  "Video");
  class_Window = mrb_class_get_under(mrb, mod_Video, "Window");

  mrb_define_method(mrb, class_Window, "change_transparency", mrb_sdl2_cocoa_change_transparency, MRB_ARGS_NONE() );
  mrb_define_method(mrb, class_Window, "change_transparency_gl_context", mrb_sdl2_cocoa_change_transparency_gl_context, MRB_ARGS_NONE() );

  arena_size = mrb_gc_arena_save(mrb);

  mrb_gc_arena_restore(mrb, arena_size);
}

void mrb_mruby_sdl2_cocoa_gem_final(mrb_state *mrb) {

}
