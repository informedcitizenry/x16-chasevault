.include "x16.inc"

.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"
   jmp start

VRAM_TILEMAP   = $04000 ; 128x128
VRAM_SPRITES   = $0E000 ; 64 4bpp 16x16 frames
VRAM_TILES     = $10000 ; 424 4bpp 16x16 (may also be used as sprite frames)
VRAM_BITMAP    = $16A00 ; 4bpp 320x240

.include "filenames.asm"
.include "loadbank.asm"
.include "loadvram.asm"
.include "superimpose.asm"
.include "irq.asm"
.include "vsync.asm"
.include "game.asm"

start:
   stz VERA_ctrl
   VERA_SET_ADDR VRAM_layer0, 0  ; disable VRAM layer 0
   lda #$FE
   and VERA_data
   sta VERA_data

   VERA_SET_ADDR VRAM_layer1, 1  ; configure VRAM layer 1
   lda #$60                      ; 4bpp tiles
   sta VERA_data
   lda #$3A                      ; 128x128 map of 16x16 tiles
   sta VERA_data
   lda #((VRAM_TILEMAP >> 2) & $FF)
   sta VERA_data
   lda #((VRAM_TILEMAP >> 10) & $FF)
   sta VERA_data
   lda #((VRAM_TILES >> 2) & $FF)
   sta VERA_data
   lda #((VRAM_TILES >> 10) & $FF)
   sta VERA_data
   lda #$00                      ; initial scroll position on screen 0
   sta VERA_data
   sta VERA_data
   sta VERA_data
   sta VERA_data

   VERA_SET_ADDR VRAM_hscale, 1  ; set display to 2x scale
   lda #64
   sta VERA_data
   sta VERA_data

   ; load VRAM data from binaries
   lda #>(VRAM_TILEMAP>>4)
   ldx #<(VRAM_TILEMAP>>4)
   ldy #<tilemap_fn
   jsr loadvram

   lda #>(VRAM_SPRITES>>4)
   ldx #<(VRAM_SPRITES>>4)
   ldy #<sprites_fn
   jsr loadvram

   lda #>(VRAM_TILES>>4)
   ldx #<(VRAM_TILES>>4)
   ldy #<tiles_fn
   jsr loadvram

   lda #>(VRAM_palette>>4)
   ldx #<(VRAM_palette>>4)
   ldy #<palette_fn
   jsr loadvram

   ; TODO: store bitmap binaries to banked RAM

   ; TODO: configure layer 0 for background bitmaps

   ; TODO: load screen 0 bitmap from banked RAM into layer 0

   ; setup game parameters and initialize states
   jsr init_game

   VERA_SET_ADDR VRAM_layer1, 0  ; enable VRAM layer 1
   lda #$01
   ora VERA_data
   sta VERA_data

   VERA_SET_ADDR VRAM_sprreg, 0  ; enable sprites
   lda #$01
   sta VERA_data

   ; setup interrupts
   jsr init_irq

mainloop:
   wai
   jsr check_vsync
   jmp mainloop  ; loop forever
