import pandas as pd
from sklearn.metrics import roc_curve, auc
import matplotlib.pyplot as plt

# Primero, necesitas tener tus datos en un DataFrame de pandas
data = {
    'Inst#': list(range(1, 21)),
    'Class': ['p', 'p', 'n', 'p', 'p', 'p', 'n', 'n', 'p', 'n'] + ['p', 'n', 'p', 'n', 'n', 'n', 'p', 'n', 'p', 'n'],
    'Score': [0.9, 0.8, 0.7, 0.6, 0.55, 0.54, 0.53, 0.52, 0.51, 0.505] + [0.4, 0.39, 0.38, 0.37, 0.36, 0.35, 0.34, 0.33, 0.3, 0.1]
}

df = pd.DataFrame(data)

# Supongamos que 'p' es positivo y 'n' es negativo, convirtiendo a valores binarios
df['Class'] = df['Class'].map({'p': 1, 'n': 0})

# Calcula TPR, FPR y umbrales
fpr, tpr, thresholds = roc_curve(df['Class'], df['Score'])

# Calcula el área bajo la curva ROC
roc_auc = auc(fpr, tpr)

# Graficar la curva ROC
plt.figure()
plt.plot(fpr, tpr, color='darkorange', lw=2, label='ROC curve (area = %0.2f)' % roc_auc)
plt.plot([0, 1], [0, 1], color='navy', lw=2, linestyle='--')
plt.xlim([0.0, 1.0])
plt.ylim([0.0, 1.05])
plt.xlabel('False Positive Rate')
plt.ylabel('True Positive Rate')
plt.title('Receiver Operating Characteristic')
plt.legend(loc="lower right")
plt.show()
