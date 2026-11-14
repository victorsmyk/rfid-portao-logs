# Instalação

1. Baixe o arquivo compactado ou clone o repositório com ```git clone https://github.com/victorsmyk/portao-backend.git```
3. Execute o arquivo .bat ou .sh de acordo com o seu sistema operacional
4. Conecte o Arduino ao seu PC por meio de uma porta USB
5. Mantenha o aplicativo aberto para a detecção e escrita dos logs
6. Verifique os logs clicando em index.html
7. A página deve ser recarregada para que um novo log seja renderizado

# Como funciona
1. O script app.js procura entre as portas seriais disponíveis aquela conectada a um Arduino UNO (ID 2341) e abre a conexão a 9600 baud.
2. Cada linha enviada pelo Arduino é lida e comparada com dois valores: "HIGH" e "LOW", com HIGH entendido como abertura com a senha correta e LOW como uma tentativa com senha incorreta.
3. Para que o script reconheça os eventos, o código executado pelo Arduino deve iniciar a comunicação serial no setup() com o mesmo baudrate usado pelo script (9600) e, depois, enviar a mensagem com Serial.println() no ponto do código em que a senha é validada. 
4. É importante usar exatamente "HIGH" e "LOW", em maiúsculas, e utilizar println em vez de print em todas as instâncias, pois a quebra de linha é o que marca o fim da mensagem para o script.
```
// rfid_app.ino
void setup() {
  Serial.begin(9600); // mesmo baudrate do script
}

void loop() {
  if (senhaCorreta()) {
    //... abrir a fechadura...
    Serial.println("HIGH");
  } else if (tentativaFeita()) {
     //... acionar alarme...
    Serial.println("LOW");
  }
}
 ```
