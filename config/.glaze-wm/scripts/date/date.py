import datetime

now = datetime.date.today()
dd = int(now.strftime("%d"))
mm = now.strftime("%B")
yy = now.strftime("%Y")

prefix = ""

match dd:
    case 1:
        prefix = "st"
    case 2:
        prefix = "nd"
    case 3:
        prefix = "rd"
    case 31:
        prefix = "st"
    case _:
        prefix = "th"

path = "C:\\Users\\Taran\\.glaze-wm\\scripts\\date\\"

formatted_string = f"{dd}{prefix} of {mm}, {yy}"
with open(f'{path}date.txt', 'w') as f:
    f.write(formatted_string)