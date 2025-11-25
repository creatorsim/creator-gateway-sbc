import gdb

class SkipEcallBreakpoint(gdb.Breakpoint):
    def __init__(self):
        # Coloca breakpoint en la función ECALL
        super().__init__("ECALL", gdb.BP_BREAKPOINT, internal=False)

    def stop(self):
        # Al llegar al breakpoint, saltamos la ejecución hasta el siguiente punto
        # Esto evita entrar en la macro ECALL
        # Avanzamos la ejecución hasta la siguiente instrucción después del call
        # Puedes ajustar esta lógica según el entorno
        print("Skipping ECALL macro")
        gdb.execute("finish")  # Ejecuta hasta salir de ECALL (si es función)
        return False  # No detener ejecución, continuar

# Instancia el breakpoint para evitar entrar en ECALL
SkipEcallBreakpoint()
