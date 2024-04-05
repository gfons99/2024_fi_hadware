import tkinter as tk
from tkinter import ttk
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import openpyxl
import matplotlib.pyplot as plt

# Función para leer los datos del archivo Excel y procesarlos
def leer_datos_excel(archivo):
    workbook = openpyxl.load_workbook(archivo)
    sheet = workbook.active
    data = {
        'Fecha': [],
        'Hora': [],
        'Temperatura': [],
        'pH': [],
        'Polution': [],
        'Conductividad': []
    }

    # Leer los datos desde la fila 2 hasta el final del archivo
    for row in sheet.iter_rows(min_row=2, values_only=True):
        fecha_str = row[0].strftime('%Y-%m-%d') if row[0] is not None else None
        hora_str = row[1].strftime('%I:%M %p') if row[1] is not None else None
        fecha_hora = f"{fecha_str} {hora_str}" if fecha_str is not None and hora_str is not None else None
        if fecha_hora:
            data['Fecha'].append(fecha_hora)
            data['Hora'].append(hora_str)
            data['Temperatura'].append(row[2])
            data['pH'].append(row[3])
            data['Polution'].append(row[4])
            data['Conductividad'].append(row[5])

    return data

def generar_graficos_por_hora(data):
    # Obtener los últimos 10 registros
    ultimos_registros = {key: value[-10:] for key, value in data.items()}

    # Configurar los límites para cada tipo de dato
    limites = {
        'Temperatura': (0, 50),
        'pH': (0, 14),
        'Polution': (0, 5),
        'Conductividad': (0, 1500)
    }

    # Crear subgráficos para cada columna por hora
    fig, axs = plt.subplots(4, 1, figsize=(10, 12))

    for i, columna in enumerate(['Temperatura', 'pH', 'Polution', 'Conductividad']):
        axs[i].plot(ultimos_registros['Hora'], ultimos_registros[columna], marker='o', markersize=5)
        axs[i].set_title(f'{columna} por hora de los últimos 10 registros')
        axs[i].set_xlabel('Hora')
        axs[i].set_ylabel(columna)
        axs[i].set_ylim(limites[columna])
        
        if columna == 'Temperatura':
            axs[i].set_yticks(range(0, 51, 10))
            axs[i].set_yticklabels(range(0, 51, 10))
        if columna == 'pH':
            axs[i].set_yticks(range(0, 15, 1))
            axs[i].set_yticklabels(range(0, 15, 1))

        axs[i].grid(True)

    # Retorna la figura en lugar de mostrarla
    return fig

# Leer los datos del archivo Excel
datos = leer_datos_excel('Data.xlsx')

# Modifica esta función para agregar las gráficas a la pestaña
def agregar_graficas(tab):
    # Utiliza la función modificada para obtener la figura con las gráficas
    datos = leer_datos_excel('Data.xlsx')
    fig = generar_graficos_por_hora(datos)
    
    # Crear un lienzo y agregar la figura
    canvas = FigureCanvasTkAgg(fig, master=tab)
    canvas.draw()
    canvas.get_tk_widget().pack(side=tk.TOP, fill=tk.BOTH, expand=1)
    
# Crear la ventana principal
root = tk.Tk()
root.title("Sistema de Monitoreo")

# Crear el control de pestañas
tab_control = ttk.Notebook(root)

# Crear la primera pestaña de gráficas
tab_horas = ttk.Frame(tab_control)
tab_control.add(tab_horas, text='Horas')
agregar_graficas(tab_horas)

# Crear la segunda pestaña de inicio
tab_lobby = ttk.Frame(tab_control)
tab_control.add(tab_lobby, text='Lobby')
mensaje_inicio = tk.Label(tab_lobby, text="Pantalla de inicio", padx=5, pady=5)
mensaje_inicio.pack()

# Posicionar el control de pestañas en la ventana
tab_control.pack(expand=1, fill='both')

# Iniciar el bucle principal de la interfaz gráfica
root.mainloop()
