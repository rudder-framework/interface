import threading
import webbrowser

import uvicorn


def main():
    threading.Timer(1.0, lambda: webbrowser.open("http://localhost:8000")).start()
    uvicorn.run("orthon_ui.server:app", host="localhost", port=8000)


if __name__ == "__main__":
    main()
