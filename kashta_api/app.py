from flask import Flask, request, jsonify
import joblib
import pandas as pd

app = Flask(__name__)

model = joblib.load("kashta_model_clean_v2.pkl")

@app.route("/predict", methods=["POST"])
def predict():
    data = request.json

    try:
        input_df = pd.DataFrame([{
            "preferredPlaceType": data["preferredPlaceType"],
            "distancePreference": data["distancePreference"],
            "temperaturePreference": data["temperaturePreference"],
            
            "placeEnvironmentType": data["placeEnvironmentType"],
            "placeDistanceBucket": data["placeDistanceBucket"],
            "placeAverageRating": float(data["placeAverageRating"]),
            "placeRatingCount": int(data["placeRatingCount"]),
            "userClickCountForPlace": int(data["userClickCountForPlace"]),
        }])

        prediction = model.predict(input_df)

        return jsonify({
            "predicted_rating": float(prediction[0])
        })

    except Exception as e:
        return jsonify({
            "predicted_rating": None,
            "error": str(e)
        }), 200

if __name__ == "__main__":
    app.run(debug=True)