using System;
using System.Collections.Generic;
using System.Configuration;
using MySql.Data.MySqlClient;
using Newtonsoft.Json;

namespace Rentas
{  public partial class Formulario : System.Web.UI.Page
    { public class Item
        {
            public string ItemNombre { get; set; }
            public decimal Precio { get; set; }
            public int Cantidad { get; set; }
            public decimal Total => Precio * Cantidad;
        } protected void btnVaciar_Click(object sender, EventArgs e)


        {
            // Para limpiarlo
            hfCarritoJSON.Value = "[]";
            lblSubtotal.Text = "$0.00";
            lblIVA.Text = "$0.00";
            lblTotal.Text = "$0.00";
        }

        protected void btnGuardar_Click(object sender, EventArgs e)
        {
            var carrito = JsonConvert.DeserializeObject<List<Item>>(hfCarritoJSON.Value);

            string connStr = ConfigurationManager.ConnectionStrings["MyConexion"].ConnectionString;
            using (var conn = new MySqlConnection(connStr))
            {
        conn.Open();
                string idCliente = Guid.NewGuid().ToString("N").Substring(0, 12);


          var cmdCliente = new MySqlCommand("INSERT INTO Clientes (id_cliente, nombre, lugar) VALUES (@id, @nombre, @lugar);", conn);
             cmdCliente.Parameters.AddWithValue("@id", idCliente);
             cmdCliente.Parameters.AddWithValue("@nombre", txtNombre.Text);
             cmdCliente.Parameters.AddWithValue("@lugar", txtLugar.Text);
             cmdCliente.ExecuteNonQuery();
          var cmdCot = new MySqlCommand("INSERT INTO Cotizaciones (id_cliente, fecha) VALUES (@id_cliente, NOW()); SELECT LAST_INSERT_ID();", conn);
                cmdCot.Parameters.AddWithValue("@id_cliente", idCliente);
                int idCotizacion = Convert.ToInt32(cmdCot.ExecuteScalar());
                




                foreach (var item in carrito)
                {
              var cmdDet = new MySqlCommand("INSERT INTO Conceptos (id_cotizacion, item, precio_unitario, dias, total) VALUES (@id, @item, @precio, @dias, @total);", conn);
                cmdDet.Parameters.AddWithValue("@id", idCotizacion);
                 cmdDet.Parameters.AddWithValue("@item", item.ItemNombre);
                 cmdDet.Parameters.AddWithValue("@precio", item.Precio);
                    cmdDet.Parameters.AddWithValue("@dias", item.Cantidad);
                    cmdDet.Parameters.AddWithValue("@total", item.Total);
                    cmdDet.ExecuteNonQuery();
                }
            }
        }

    }
}
