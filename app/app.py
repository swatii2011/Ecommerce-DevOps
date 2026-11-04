
from flask import Flask, jsonify, request, render_template_string

app = Flask(__name__)

products = [
    {"id": 1, "name": "Laptop", "price": 55000},
    {"id": 2, "name": "Smartphone", "price": 25000},
    {"id": 3, "name": "Headphones", "price": 2500},
    {"id": 4, "name": "Smart Watch", "price": 5000}
]

cart = []

HTML = """
<!DOCTYPE html>
<html>
<head>
    <title>ShopEasy - E-Commerce</title>
    <style>
        body { font-family: Arial; background: #f4f6f9; margin: 40px; }
        h1 { color: #263c63; }
        .product { background: white; padding: 20px; margin: 15px;
                   border-radius: 10px; display: inline-block; width: 200px; }
        button { background: #263c63; color: white; border: 0;
                 padding: 10px; cursor: pointer; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>ShopEasy - Online Store</h1>
    <h3>Available Products</h3>
    {% for p in products %}
    <div class="product">
        <h3>{{ p.name }}</h3>
        <p>Price: ₹{{ p.price }}</p>
        <form action="/add/{{ p.id }}" method="post">
            <button type="submit">Add to Cart</button>
        </form>
    </div>
    {% endfor %}
    <h3><a href="/cart">View Shopping Cart</a></h3>
</body>
</html>
"""

@app.route("/")
def home():
    return render_template_string(HTML, products=products)

@app.route("/add/<int:product_id>", methods=["POST"])
def add_to_cart(product_id):
    product = next((p for p in products if p["id"] == product_id), None)
    if product:
        cart.append(product)
    return "<h2>Product added!</h2><a href='/'>Continue Shopping</a>"

@app.route("/cart")
def view_cart():
    total = sum(item["price"] for item in cart)
    return jsonify({"cart": cart, "total": total})

@app.route("/checkout", methods=["POST"])
def checkout():
    global cart
    total = sum(item["price"] for item in cart)
    cart = []
    return jsonify({"message": "Order placed successfully", "total": total})

@app.route("/health")
def health():
    return jsonify({"status": "healthy", "application": "ShopEasy"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
