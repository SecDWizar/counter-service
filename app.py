from flask import Flask, request
import redis
import sys

if getattr(sys, 'frozen', False):
    template_folder = os.path.join(sys._MEIPASS, 'templates')
    static_folder = os.path.join(sys._MEIPASS, 'static')
    app = Flask(__name__, template_folder=template_folder, static_folder=static_folder)
else:
    app = Flask(__name__, static_folder='static')

r = redis.Redis(host='redis', port=6379)

@app.route('/', defaults={'path': ''}, methods = ['GET', 'POST'])
@app.route('/<path:path>', methods = ['GET', 'POST'])
def catch_all(path):
    
    app.logger.info(path)
    
    if request.method == 'POST':
        """update counter"""
        
        r.incr("counter") 
        return r.get("counter")
    
    if request.method == 'GET':
        """return total posts counter"""
        
        if r.exists("counter"):
            return r.get("counter")
        else:
            return "0" 

if __name__ == '__main__':
    app.run(host= '0.0.0.0', port=8000)

