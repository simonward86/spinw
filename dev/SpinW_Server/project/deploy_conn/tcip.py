import socket
from subprocess import Popen
from project import config
import time
import os
from pathlib import Path
import atexit

class tcip:
    def __init__(self, host, port=13001):
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.port = port
        self.host = host
        self.is_connected = False
        self.process = None

    def __del__(self):
        if self.is_connected:
            self.socket.close()

    def connect(self):
        if not self.is_connected:
            self.process = Popen([config.get('DEPLOY_PATH'),os.path.join(Path(__file__).parents[2],
                                    config.get('UPLOAD_FOLDER')), str(config.get('CORES')), str(self.port)])
            atexit.register(self.process.terminate)
            time.sleep(5)
            self.socket.connect((self.host, self.port))
            self.is_connected = True

    def send_comand(self, cmd):
        try:
            if self.is_connected:
                self.socket.sendall(cmd.encode('utf-8'))
            else:
                self.connect()
                self.socket.sendall(cmd.encode('utf-8'))
            return True
        except:
            self.is_connected = False
            self.process.kill()
            time.sleep(1)
            self.connect()
            self.socket.sendall(cmd.encode('utf-8'))
            return False
