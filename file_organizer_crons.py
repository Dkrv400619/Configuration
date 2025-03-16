import os
import shutil

# Obtendo automaticamente o caminho do usuário
home_dir = os.path.expanduser('~')

# Diretórios de origem e destino
caminho_origem = os.path.join(home_dir, 'Downloads')  # Diretório de Downloads
caminho_destino_base = os.path.join(home_dir, 'Bunker/Files')  # Diretório base para categorizar arquivos
caminho_destino_appimage = os.path.join(home_dir, 'Bunker/applications')  # Diretório para arquivos .AppImage
caminho_destino_Programming = os.path.join(home_dir, 'Bunker/Programming')  # Diretório para arquivos de programação


# Estrutura de diretórios de destino
destinos = {
    'Documents': ['.pdf', '.docx', '.txt', '.pptx', '.xlsx', '.csv'],
    'Images': ['.png', '.jpeg'],
    'Music': ['.mp3'],
    'Videos': ['.mp4'],
    'Programming': ['.py', '.css', '.html', '.php', '.sh', '.c', '.asm'],
    'Compact': ['.deb', '.zip', '.gz', '.7z', '.zst', '.xz'],
}

# Função para mover arquivos
def organizar_arquivos(caminho_origem):
    for arquivo in os.listdir(caminho_origem):
        caminho_arquivo = os.path.join(caminho_origem, arquivo)
        if not os.path.isfile(caminho_arquivo):  # Ignorar diretórios
            continue

        nome_arquivo, extensao = os.path.splitext(arquivo)
        extensao = extensao.lower()

        # Caso especial para arquivos .AppImage
        if extensao == '.appimage':
            os.makedirs(caminho_destino_appimage, exist_ok=True)
            shutil.move(caminho_arquivo, os.path.join(caminho_destino_appimage, arquivo))
            print(f'Movendo {arquivo} para applications')
            continue  # Pula para o próximo arquivo

        # Verifica se a extensão pertence a alguma categoria
        for pasta, extensoes in destinos.items():
            if extensao in extensoes:
                caminho_destino = os.path.join(caminho_destino_base, pasta)
                os.makedirs(caminho_destino, exist_ok=True)
                shutil.move(caminho_arquivo, os.path.join(caminho_destino, arquivo))
                print(f'Movendo {arquivo} para {pasta}')
                break  # Sai do loop assim que encontrar a categoria correta

if __name__ == "__main__":
    organizar_arquivos(caminho_origem)

