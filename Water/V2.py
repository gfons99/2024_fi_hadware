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

# Función para generar gráficos por hora
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

    # Crear gráficos para cada columna por hora
    for columna in ['Temperatura', 'pH', 'Polution', 'Conductividad']:
        plt.figure(figsize=(10, 6))
        for i, registro in enumerate(ultimos_registros[columna]):
            plt.plot([i], [registro], marker='o', markersize=5, label=f'Registro {i+1}')

        plt.title(f'{columna} por hora de los últimos 10 registros')
        plt.xlabel('Hora')
        plt.ylabel(columna)
        plt.xticks(range(10), ultimos_registros['Hora'], rotation=45)
        plt.ylim(limites[columna])
        plt.legend()
        plt.grid(True)
        plt.tight_layout()
        plt.show()

# Leer los datos del archivo Excel
datos = leer_datos_excel('Data.xlsx')

# Generar gráficos por hora
generar_graficos_por_hora(datos)
