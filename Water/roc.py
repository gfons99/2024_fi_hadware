import pandas as pd
import numpy as np
import matplotlib.pyplot as plt



#Primero, necesitas tener tus datos en un DataFrame de pandas
data = {
    'Inst#': list(range(1, 21)),
    'Class': ['p', 'p', 'n', 'p', 'p', 'p', 'n', 'n', 'p', 'n'] + ['p', 'n', 'p', 'n', 'n', 'n', 'p', 'n', 'p', 'n'],
    'Score': [0.9, 0.8, 0.7, 0.6, 0.55, 0.54, 0.53, 0.52, 0.51, 0.505] + [0.4, 0.39, 0.38, 0.37, 0.36, 0.35, 0.34, 0.33, 0.3, 0.1]
}

df = pd.DataFrame(data)

# Ordenamos los datos por la columna 'Score' de mayor a menor
df_sorted = df.sort_values(by='Score', ascending=False)

# Inicializamos las listas para TPR y FPR
tprs = []
fprs = []

# Obtenemos el número total de positivos y negativos
P = sum(df_sorted['Class'] == 1)
N = sum(df_sorted['Class'] == 0)

# Verificar si P o N es cero y manejar el caso adecuadamente
if P == 0 or N == 0:
    raise ValueError("No hay instancias suficientes de una de las clases.")

# Inicializamos los verdaderos positivos y falsos positivos acumulados
tp = 0
fp = 0

# Calculamos TPR y FPR para cada umbral
for i in df_sorted.itertuples():
    # Si la instancia actual es positiva
    if i.Class == 1:
        tp += 1
    else:
        fp += 1
    tprs.append(tp / P)
    fprs.append(fp / N)

# Asegúrate de que el primer punto de la curva ROC es (0,0) y el último es (1,1)
fprs = [0] + fprs + [1]
tprs = [0] + tprs + [1]

# Graficamos la curva ROC
plt.figure()
plt.plot(fprs, tprs, marker='o')
plt.plot([0, 1], [0, 1], linestyle='--', color='grey') # línea de no-discriminación
plt.xlabel('False Positive Rate')
plt.ylabel('True Positive Rate')
plt.title('ROC Curve')
plt.show()