docker run \
-it \
--name simplex --rm \
-p 3000:3000 \
-v /home/djcharles26/development/flutter:/home/djcharles26/development/flutter \
-v /home/djcharles26/Documents/Universidad/septimo\ \semestre/Modelos/simplex/simplex:/home/gepp \
-e PORT=3000 \
tng/simplex:development /bin/bash
