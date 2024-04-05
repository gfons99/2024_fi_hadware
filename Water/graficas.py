import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
from scipy.interpolate import make_interp_spline
import numpy as np

# Colores de la escala de pH como en la imagen proporcionada
ph_scale_colors = [
    "#ff1a1a", "#ff751a", "#ffcc00", "#ffff00",
    "#ccff00", "#80ff00", "#00ff00", "#00ff80",
    "#00ffbf", "#00ffff", "#0080ff", "#0000ff",
    "#8000ff", "#bf00ff"
]
def animate(i):
    # Leer los datos del archivo Excel
    data = pd.read_excel('ph.xlsx', usecols=['A', 'B'])
    
    # Asegurarse de que las fechas están en formato correcto y filtrar los últimos 10 datos
    data = data.tail(10)
    data['B'] = pd.to_datetime(data['B']).dt.strftime('%H:%M')  # Asegurar formato de hora
    
    # Limpia la figura actual para la actualización del gráfico
    plt.cla()
    
    # Establecer el fondo de la gráfica según la escala de pH
    for idx, color in enumerate(ph_scale_colors, start=1):
        plt.axhspan(idx-1, idx, color=color, alpha=0.5)
    
    # Interpolación spline para suavizar la línea
    # [...] (La interpolación sigue igual)
    
    # Graficar la línea suavizada
    plt.plot(data['B'], data['A'], color='black')
    
    # Configurar las etiquetas del eje x para que muestren las horas correctas
    plt.xticks(rotation=45)
    
    # Ajustar los límites del eje x para mostrar solo los últimos 10 registros
    if len(data) > 10:
        plt.xlim(data['B'].iloc[-10], data['B'].iloc[-1])
    else:
        plt.xlim(data['B'].iloc[0], data['B'].iloc[-1])
    
    # Configuración de los ejes y título
    plt.ylim(0, 14)
    plt.xlabel('Hora')
    plt.ylabel('pH')
    plt.tight_layout()

# Configurar la figura de Matplotlib y la animación
plt.figure(figsize=(10, 5))
ani = FuncAnimation(plt.gcf(), animate, interval=1000)

# Mostrar la gráfica
plt.show()