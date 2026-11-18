
# 📦 Flutter Web + Serverless Backend

![Flutter](https://img.shields.io/badge/Flutter-Web-blue?logo=flutter)
![AWS](https://img.shields.io/badge/AWS-Serverless-orange?logo=amazonaws)
![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)

Proyecto con:

- 🎯 **Frontend:** Flutter Web
- ⚙️ **Backend:** Serverless (AWS Lambda)
- 🐳 **Ejecución local:** Docker

---

## 🚀 Ejecutar Frontend

```bash
# Construir y ejecutar en un solo comando
docker build --no-cache -t flutter-web . && docker run -p 5000:5000 flutter-web
```

---

## 🚀 Ejecutar Backend

```bash
# Hacer comando
npx serverless deploy
```

---

## 🚀 Compilar Web
```bash
# Hacer comando
flutter build web --base-href /app/
```

