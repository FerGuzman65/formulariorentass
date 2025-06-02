
<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Formulario.aspx.cs" Inherits="Rentas.Formulario" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8" />
    <title>Formulario Renta de Equipos</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet" />
    <style>



        .btn-editar
        {
            background-color: #ffc107;
            color: #000;
        }

        .dropdown-dias 
        {
            position: relative;
        }
        .dropdown-menu-dias 
        {
            position: absolute;
            top: 40px;
            left: 0;
            background-color: #fff;
            padding: 10px;
            border: 1px solid #ccc;
            box-shadow: 0 2px 5px rgba(0,0,0,0.2);
            display: none;
            z-index: 1000;
            width: 250px;
        }
        .dropdown-dias.show .dropdown-menu-dias
        {
            display: block;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server" class="container mt-5">
        <h2 class="mb-4">Cotización de Renta</h2>

        <div class="row mb-4">
            <div class="col-md-4">
            <label>Nombre:</label>
            <asp:TextBox ID="txtNombre" runat="server" CssClass="form-control" />
            </div>
            <div class="col-md-4">
                <label>Lugar:</label>
                <asp:TextBox ID="txtLugar" runat="server" CssClass="form-control" />
            </div>
        </div>
        <button type="button" class="btn btn-secondary mb-4 me-2" onclick="mostrarCatalogo()">Catálogo</button>
 <h4>Buscar equipo</h4>
        <div class="mb-3">
        <input type="text" id="buscador" class="form-control" placeholder="Buscar equipo..." />
        </div>
        <ul id="resultados" class="list-group mb-4"></ul>

        <div id="catalogo" class="mb-4" style="display:none;">
        <h4>Catálogo de Equipos</h4>
        <table class="table table-striped">
                <thead><tr><th>Equipo</th><th>Precio por día</th></tr></thead>
                <tbody id="tablaCatalogo"></tbody>
            </table>
        </div>



        <h4>Carrito de Equipos</h4>
        <table class="table table-bordered" id="tablaCarrito">
            <thead>
                <tr>
                    <th>Item</th>
                    <th>Precio</th>
                    <th>Días</th>
                    <th>Descuento</th>
                    <th>Total</th>
                 <th>Editar</th>
                 <th>Eliminar</th>
             </tr>
            </thead>
         <tbody></tbody>
        </table>

        <asp:HiddenField ID="hfCarritoJSON" runat="server" />
        <div class="mt-3">
            <p><strong>Subtotal:</strong> <asp:Label ID="lblSubtotal" runat="server" /></p>
            <p><strong>IVA (16%):</strong> <asp:Label ID="lblIVA" runat="server" /></p>
            <p class="fs-5 fw-bold">Total: <asp:Label ID="lblTotal" runat="server" /></p>
        </div>
        <asp:Button ID="btnVaciar" runat="server" Text="Vaciar carrito" CssClass="btn btn-danger mt-3" OnClick="btnVaciar_Click" />
        <asp:Button ID="btnGuardar" runat="server" Text="Guardar Cotización" CssClass="btn btn-primary mt-3 ms-3" OnClick="btnGuardar_Click" />
    </form>

    <script>
        const precios = {
            "Cámara Alexa 35": 23500, "Cámara Alexa Mini LF":18500, "Cámara Alexa Mini": 12500,
            "Set de Lentes Arri Zeiss": 7125,
            "Zoom Optimo 24-290mm": 7125,
            "Monitor Atmos Neon": 2175,
            "Dana Dolly": 0,
            "Dolly Doorway Matthews": 0,
            "Riel Recto para dolly (8)": 420,
            "Grúa CamMate Travel": 6800,
            "Batería Block VCLX": 1200,
            "Batería Aputure Delta": 2000,
            "Teradek SDI/HD": 2500,
            "Follow Focus inalámbrico": 2800,
            "Cables SDI": 3000,
            "Intercomunicadores": 1500,
            "Móvil Express (solo tramoya)": 4500
        };

        const buscador = document.getElementById("buscador");
        const resultados = document.getElementById("resultados");
        const tabla = document.querySelector("#tablaCarrito tbody");
        const hidden = document.getElementById("<%= hfCarritoJSON.ClientID %>");
        let carrito = [];
        buscador.addEventListener("input", () => {
            resultados.innerHTML = "";
            const query = buscador.value.toLowerCase();
            Object.keys(precios).forEach(nombre => {
                if (nombre.toLowerCase().includes(query)) {
                    const li = document.createElement("li");
                    li.className = "list-group-item dropdown-dias";
                    li.innerHTML = `
                        ${nombre} - $${precios[nombre]}
                        <button class='btn btn-sm btn-outline-secondary float-end' type='button'>▼</button>
                        <div class='dropdown-menu-dias'>
                            <label>Días:</label>
                            <input type='number' min='1' value='1' class='form-control mb-2' id='dias_${nombre}' oninput='actualizarTotal("${nombre}")' />
                            <label>Descuento (%):</label>
                            <input type='range' min='0' max='40' value='0' class='form-range' id='desc_${nombre}' oninput='actualizarTotal("${nombre}")'>
                            <small id='label_${nombre}'>0%</small>
                            <p class='mt-2'>Total estimado: $<span id='total_${nombre}'>0.00</span></p>
                            <button class='btn btn-success btn-sm mt-2' type='button' onclick='agregar("${nombre}", ${precios[nombre]}, document.getElementById("dias_${nombre}").value, document.getElementById("desc_${nombre}").value)'>Agregar</button>
                        </div>`;
                    li.querySelector("button").addEventListener("click", function (e) {
                        e.stopPropagation();
                        li.classList.toggle("show");
                        actualizarTotal(nombre);
                    }
                    );
                    resultados.appendChild(li);
                }
            }
            );
        }
        );
        function actualizarTotal(nombre) {
          const dias = parseInt(document.getElementById(`dias_${nombre}`).value) || 0;
            const desc = parseInt(document.getElementById(`desc_${nombre}`).value) || 0;
            const base = precios[nombre];
            const total = (base * dias) * (1 - desc / 100);
            document.getElementById(`label_${nombre}`).innerText = desc + "%";
            document.getElementById(`total_${nombre}`).innerText = total.toFixed(2);
        }

        function mostrarCatalogo() {
            const catalogo = document.getElementById("catalogo");
            catalogo.style.display = catalogo.style.display === "block" ? "none" : "block";
            const tablaCatalogo = document.getElementById("tablaCatalogo");
            tablaCatalogo.innerHTML = "";
            Object.entries(precios).forEach(([nombre, precioBase]) => {
                const tr = document.createElement("tr");
                const tdNombre = document.createElement("td");
                tdNombre.textContent = nombre;
                const tdPrecio = document.createElement("td");
                const precioSpan = document.createElement("span");
                precioSpan.textContent = `$${precioBase.toFixed(2)}`;
                tdPrecio.appendChild(precioSpan);
                tr.appendChild(tdNombre);
                tr.appendChild(tdPrecio);
                tablaCatalogo.appendChild(tr);
            });
        }


        function agregar(nombre, precio, cantidad, descuento = 0) {
            cantidad = parseInt(cantidad);
            descuento = parseInt(descuento);
            if (cantidad <= 0) return;
            resultados.innerHTML = "";
            buscador.value = "";
            const existente = carrito.find(i => i.ItemNombre === nombre);
            if (existente) {
                existente.Cantidad += cantidad;
                existente.Descuento = descuento;
            } else {
                carrito.push({ ItemNombre: nombre, Precio: precio, Cantidad: cantidad, Descuento: descuento });
            }
            renderizar();
        }


        function eliminar(index) {
            carrito.splice(index, 1);
            renderizar();
        }
        function editar(index) {
            const item = carrito[index];
            const nuevaFila = `
                <tr>
                    <td>${item.ItemNombre}</td>
                    <td>$${item.Precio}</td>
                    <td><input type='number' min='1' value='${item.Cantidad}' class='form-control form-control-sm' id='editDias_${index}'></td>
                    <td><input type='number' min='0' max='40' value='${item.Descuento || 0}' class='form-control form-control-sm' id='editDesc_${index}'></td>
                    <td></td>
                    <td colspan='2'>
                        <button class='btn btn-primary btn-sm' onclick='guardarEdicion(${index})'>Guardar</button>
                    </td>
                </tr>`;
            tabla.rows[index].innerHTML = nuevaFila;
        }

        function guardarEdicion(index) {
            const dias = parseInt(document.getElementById(`editDias_${index}`).value);
            const desc = parseInt(document.getElementById(`editDesc_${index}`).value);
            if (dias > 0 && desc >= 0) {
                carrito[index].Cantidad = dias;
                carrito[index].Descuento = desc;
                renderizar();
            }
        }

        function renderizar()

        {
            tabla.innerHTML = "";
            let subtotal = 0;
            carrito.forEach((item, index) => {
                const total = (item.Precio * item.Cantidad) * (1 - (item.Descuento || 0) / 100);
                subtotal += total;
                tabla.innerHTML += `
                    <tr>
                    <td>${item.ItemNombre}</td>
                    <td>$${item.Precio}</td>
                        <td>${item.Cantidad}</td>
                        <td>${item.Descuento || 0}%</td>
                        <td>$${total.toFixed(2)}</td>
                        <td><button class="btn btn-editar btn-sm" onclick="editar(${index})">Editar</button></td>
                        <td><button class="btn btn-danger btn-sm" onclick="eliminar(${index})">🗑️</button></td>
                    </tr>`;
            }
            );
         const iva = subtotal * 0.16;
         const total = subtotal + iva;
            document.getElementById("<%= lblSubtotal.ClientID %>").innerText = "$" + subtotal.toFixed(2);
            document.getElementById("<%= lblIVA.ClientID %>").innerText = "$" + iva.toFixed(2);
            document.getElementById("<%= lblTotal.ClientID %>").innerText = "$" + total.toFixed(2);
            hidden.value = JSON.stringify(carrito); }


    </script>
</body>
</html>