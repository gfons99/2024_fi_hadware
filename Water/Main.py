import tkinter as tk
from tkinter import ttk
from PIL import Image, ImageTk
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg


class Aplicacion:
    def __init__(self, root):
        self.root = root
        self.root.title("Aplicación con Interfaz Gráfica Avanzada")

        # Crear pestañas
        self.tabControl = ttk.Notebook(self.root)

        # Pestaña 1: Imágenes
        self.tab1 = ttk.Frame(self.tabControl)
        self.tabControl.add(self.tab1, text='Imágenes')
        self.mostrar_imagen()

        # Pestaña 2: Gráficas
        self.tab2 = ttk.Frame(self.tabControl)
        self.tabControl.add(self.tab2, text='Gráficas')
        self.mostrar_grafica()

        self.tabControl.pack(expand=1, fill="both")

    def mostrar_imagen(self):
        imagen = Image.open("imagen.jpg")
        imagen = imagen.resize((300, 300))
        foto = ImageTk.PhotoImage(imagen)
        label = tk.Label(self.tab1, image=foto)
        label.image = foto
        label.pack()

    def mostrar_grafica(self):
        fig, ax = plt.subplots()
        x = [1, 2, 3, 4, 5]
        y = [2, 3, 5, 7, 11]
        ax.plot(x, y)
        canvas = FigureCanvasTkAgg(fig, master=self.tab2)
        canvas.draw()
        canvas.get_tk_widget().pack()


if __name__ == "__main__":
    root = tk.Tk()
    app = Aplicacion(root)
    root.mainloop()
