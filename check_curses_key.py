import time
import curses



def draw(canvas):
    canvas.keypad(True)  # нужно для работы с клавишами F1-F4
    while True:
        key = canvas.getkey()
        if key == ("\x1b"):
            print(f"Вы ввели Escape!")
        print(f"Вы ввели {key.encode()}")
    
  
if __name__ == '__main__':
    curses.update_lines_cols()
    curses.wrapper(draw)
