from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import os
from openai import OpenAI

app = FastAPI(title="TheApp API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY", ""))


class Transaction(BaseModel):
    id: str
    description: str
    amount: float
    date: str
    category: str
    isExpense: bool


class Budget(BaseModel):
    id: str
    category: str
    limit: float
    spent: float


class InsightsRequest(BaseModel):
    transactions: List[Transaction]
    budgets: List[Budget]


class CategorizeRequest(BaseModel):
    description: str


CATEGORY_RULES = {
    "Comida": [
        "starbucks",
        "cafe",
        "restaurant",
        "mcdonald",
        "pizza",
        "comida",
        "almuerzo",
        "cena",
    ],
    "Transporte": [
        "uber",
        "taxi",
        "gasolina",
        "combustible",
        "metro",
        "bus",
        "taxi",
        "peaje",
    ],
    "Entretenimiento": ["netflix", "spotify", "amazon", "pelicula", "cine", "juego"],
    "Compras": ["supermercado", "walmart", "tienda", "compra", "mercadona"],
    "Salud": ["farmacia", "doctor", "medico", "hospital", "medicina"],
    "Otros": [],
}


def local_categorize(description: str) -> str:
    desc = description.lower()
    for category, keywords in CATEGORY_RULES.items():
        if category == "Otros":
            continue
        for keyword in keywords:
            if keyword in desc:
                return category
    return "Otros"


@app.get("/")
def root():
    return {"message": "TheApp API is running", "version": "1.0.0"}


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.post("/api/ai/categorize")
def categorize(request: CategorizeRequest):
    category = local_categorize(request.description)
    return {"category": category}


@app.post("/api/ai/insights")
def get_insights(request: InsightsRequest):
    if not client.api_key:
        return {
            "resumen": "API key de OpenAI no configurada. Configure OPENAI_API_KEY en el archivo .env",
            "consejos": [
                "Configure su API key de OpenAI para obtener análisis personalizados",
                "Mientras tanto, use la categorización automática básica",
            ],
            "alerta": None,
        }

    transactions_data = [
        {
            "description": t.description,
            "amount": t.amount,
            "date": t.date,
            "category": t.category,
            "isExpense": t.isExpense,
        }
        for t in request.transactions
    ]

    budgets_data = [
        {"category": b.category, "limit": b.limit, "spent": b.spent}
        for b in request.budgets
    ]

    total_expenses = sum(t.amount for t in request.transactions if t.isExpense)
    total_income = sum(t.amount for t in request.transactions if not t.isExpense)

    category_totals = {}
    for t in request.transactions:
        if t.isExpense:
            category_totals[t.category] = category_totals.get(t.category, 0) + t.amount

    top_category = (
        max(category_totals, key=category_totals.get) if category_totals else None
    )

    system_prompt = """Eres un asesor financiero personal experto, analítico pero motivador. 
Analiza el JSON de transacciones y presupuestos del usuario.
Responde SOLO en formato JSON con esta estructura exacta:
{
    "resumen": "un párrafo resumiendo la situación financiera del usuario",
    "consejos": ["consejo 1", "consejo 2", "consejo 3"],
    "alerta": "una alerta importante si hay sobregiros o gastos excesivos, o null si todo está bien"
}
No incluyas ningún texto fuera del JSON."""

    user_prompt = f"""Datos del usuario:
Transacciones: {transactions_data}
Presupuestos: {budgets_data}
Total gastos: ${total_expenses:.2f}
Total ingresos: ${total_income:.2f}
Categoría con más gastos: {top_category or "Ninguna"}

Genera insights financieros personalizados."""

    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            temperature=0.7,
            max_tokens=500,
        )

        import json

        result_text = response.choices[0].message.content.strip()
        if result_text.startswith("```json"):
            result_text = result_text[7:]
        if result_text.endswith("```"):
            result_text = result_text[:-3]

        return json.loads(result_text.strip())
    except Exception as e:
        return {
            "resumen": f"Análisis automático: Gastaste ${total_expenses:.2f} con ingresos de ${total_income:.2f}. {'Estás gastando más de lo que ganas' if total_expenses > total_income else 'Tus gastos están bajo control'}.",
            "consejos": [
                f"Tu categoría principal de gasto es {top_category or 'desconocida'}"
                if top_category
                else "Agrega más transacciones para obtener mejores consejos",
                "Revisa tus gastos en {top_category} si es posible"
                if top_category
                else "Comienza a registrar tus gastos para ver análisis detallados",
                "Intenta ahorrar al menos el 20% de tus ingresos",
            ],
            "alerta": "⚠️ Estás gastando más de lo que ganas"
            if total_expenses > total_income
            else None,
        }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
