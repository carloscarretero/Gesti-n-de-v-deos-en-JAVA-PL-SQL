import java.sql.*;
import java.sql.Types;
import java.util.Scanner;

import oracle.jdbc.internal.OracleTypes;

public class Main
{
	// Conexion con la base de datos para todo el programa
	static Connection currCon = null;
	static Scanner reader = new Scanner(System.in);
	static CallableStatement cs;
	
	/**
	 * Contiene todas las opciones relacionadas con los CRUDS de video y los comentarios:
	 * 		1. Ver información general del video
	 * 		2. Votar un video postivia/negativamente
	 * 		3. Comentar un video
	 * 		4. Ver una lista de comentarios de un video
	 * 		5. Votar un comentario positiva/negativamente
	 * 		6. Actualizar la información de un video
	 * 		8. Eliminar el video
	 * 		9. Salir al menú anterior
	 * Si un usuario intenta realizar una acción diseñada para el autor, sin serlo, saltará una excepción
	 * controlada
	 * @param id_user - ID del usuario con sesión actual
	 * @param user - Nombre del usuario con sesión actual
	 * @param canal - Nombre del canal del video actual
	 * @param id_canal - Id del del canal del video actual
	 * @param video - Nombre del video sobre el que se desplegaran las opciones
	 * @throws Exception
	 */
	public static void opcionesVideo(int id_user, String user, String canal, int id_canal, String video) throws Exception
	{
		int op = -1;
		cs = currCon.prepareCall("{ ? = call P6.GET_ID_VIDEO(?,?) }");
		cs.registerOutParameter(1, Types.INTEGER);
		cs.setString(2, canal);
		cs.setString(3, video);
		cs.executeUpdate();
		int id_video = cs.getInt(1);

		while(op != 9)
		{
			while(op < 1 || 9 < op)
			{
				System.out.print("--------------------------------------------------\n" + 
					"Elija una opcion para el video " + video +  " del canal " + canal + ", " + user + "\n" +
					"\t1 - Ver información general\n" +
					"\t2 - Votar video\n" +
					"\t3 - Comentar video\n" + 
					"\t4 - Lista de comentarios\n" + 
					"\t5 - Votar comentario\n" +
					"\t6 - Actualizar video\n" + 
					"\t8 - Eliminar video\n" + 
					"\t9 - Salir\n" +  
					"Opcion: ");
				op = (int) reader.next().charAt(0);
				op -= 48;
			}
			if(op == 1)
			{ // 1 - Ver información general
				cs = currCon.prepareCall("{ ? = call P6.INFORMACION_VIDEO(?,?) }");
				cs.registerOutParameter(1, OracleTypes.CURSOR);
				cs.setInt(2, id_canal);
				cs.setInt(3, id_video);
				cs.executeUpdate();
				ResultSet rs = (ResultSet) cs.getObject(1);
				rs.next();
				System.out.println("Nombre: " + rs.getString("n") + 
						"\nDuracion: " + rs.getInt("d") + 
						"\nVotos positivos: " + rs.getInt("cb") + 
						"\nVotos negativos: " + rs.getInt("cm"));
				op = 0;
				
				reader.nextLine();
				System.out.print("Pulse Intro para continuar...");
				reader.nextLine();
			}
			else if (op == 2)
			{ // 2 - Votar video
				int voto = -1;
				while(voto < 0 || 1 < voto)
				{
					System.out.print( "Elija un voto\n" + 
						"\t0 - Positivo\n" + 
						"\t1 - Negativo\n" + 
						"Voto: ");
					voto = (int) reader.next().charAt(0);
					voto -= 48;
				}
				cs = currCon.prepareCall("{ call P6.VOTAR_VIDEO(?, ?, ?) }"); 
				cs.setInt(1, id_canal);
				cs.setInt(2, id_video);
				cs.setInt(3, voto);
				cs.executeUpdate();
				System.out.println("Voto realizado");
				op = 0;
				
				reader.nextLine();
				System.out.print("Pulse Intro para continuar...");
				reader.nextLine();
			}
			else if (op == 3)
			{ // 3 - Comentar video
				System.out.print("Comentario: ");
				reader.nextLine();
				String texto = reader.nextLine();
				cs = currCon.prepareCall("{ call P6.COMENTAR_VIDEO(?, ?, ?, ?) }");
				cs.setInt(1, id_user);
				cs.setInt(2, id_canal);
				cs.setInt(3, id_video);
				cs.setString(4, texto);
				cs.executeUpdate();
				System.out.println("Comentario realizado");
				op = 0;
				
				reader.nextLine();
				System.out.print("Pulse Intro para continuar...");
				reader.nextLine();
			}
			else if (op == 4)
			{ // 4 - Lista de comentarios
				cs = currCon.prepareCall("{ ? = call P6.LISTA_COMENTARIOS(?, ?) }");
				cs.registerOutParameter(1, OracleTypes.CURSOR);
				cs.setInt(2, id_canal);
				cs.setInt(3, id_video);
				cs.executeUpdate();
				ResultSet rs = (ResultSet) cs.getObject(1);
				while(rs.next())
				System.out.println("Comentario " + rs.getString("id") + 
						"\n\tAutor: " + rs.getString("autor") + 
						"\n\tTexto: " + rs.getString("texto") + 
						"\n\tVotos pos:  " + rs.getInt("cb") + 
						"\n\tVotos neg:  " + rs.getInt("cm"));
				op = 0;
				
				reader.nextLine();
				System.out.print("Pulse Intro para continuar...");
				reader.nextLine();
			}
			else if (op == 5)
			{ // 5 - Votar comentario
				int voto = -1;
				System.out.print("Numero de comentario: ");
				int id_comentario = reader.nextInt();
				while(voto < 0 || 1 < voto)
				{
					System.out.print( "Elija un voto\n" + 
						"\t0 - Positivo\n" + 
						"\t1 - Negativo\n" + 
						"Voto: ");
					voto = (int) reader.next().charAt(0);
					voto -= 48;
				}
				cs = currCon.prepareCall("{ call P6.VOTAR_COMENTARIO(?, ?, ?, ?) }"); 
				cs.setInt(1, id_canal);
				cs.setInt(2, id_video);
				cs.setInt(3, id_comentario);
				cs.setInt(4, voto);
				cs.executeUpdate();
				System.out.println("Voto realizado");
				op = 0;
				
				reader.nextLine();
				System.out.print("Pulse Intro para continuar...");
				reader.nextLine();
			}
			else if (op == 6)
			{ //6 - Actualizar video
				cs = currCon.prepareCall("{ call P6.VER_SI_PROPIETARIO(?, ?) }"); 
				cs.setString(1, user);
				cs.setString(2, canal);
				try
				{
					cs.executeUpdate();
					reader.nextLine();
					System.out.print("Nuevo nombre: ");
					String nuevoNombre = reader.nextLine();
					System.out.print("Nueva duracion: ");
					int nuevaDuracion = reader.nextInt();
					
					cs = currCon.prepareCall("{ call P6.ACTUALIZAR_VIDEO(?, ?, ?, ?) }");
					cs.setString(1, nuevoNombre);
					cs.setInt(2, nuevaDuracion);
					cs.setInt(3, id_canal);
					cs.setInt(4, id_video);
					cs.executeUpdate();
					System.out.println("Actualizacion realizada");
					video = nuevoNombre;
					op = 0;
				}
				catch(SQLException ee) { System.out.println(ee.getMessage()); op = 0;}
				
				reader.nextLine();
				System.out.print("Pulse Intro para continuar...");
				reader.nextLine();
			}
			else if (op == 8)
			{ // 8 - Eliminar video
				cs = currCon.prepareCall("{ call P6.VER_SI_PROPIETARIO(?, ?) }"); 
				cs.setString(1, user);
				cs.setString(2, canal);
				try
				{
					cs.executeUpdate();
					cs = currCon.prepareCall("{ call P6.ELIMINAR_VIDEO(?, ?) }");
					cs.setInt(1, id_canal);
					cs.setInt(2, id_video);	
					System.out.println("Eliminando video...");
					cs.executeUpdate();
					op = 9;
				}
				catch(SQLException ee) { System.out.println(ee.getMessage()); op = 0;}
				
				reader.nextLine();
				System.out.print("Pulse Intro para continuar...");
				reader.nextLine();
			}
		}
	}
	
	
	/**
	 * Contiene todas las opciones para gestionar un canal y crear y listar videos de ese canal:
	 * 		1. Ver información general
	 * 		2. Lista de videos
	 * 		3. Ver video
	 * 		4. Crear video
	 * 		5. Cambiar nombre del canal
	 * 		6. Seguir canal
	 * 		8. Eliminar canal
	 * 		9. Salir al menú anterior
	 * Si un usuario intenta realizar una acción diseñada para el autor, sin serlo, saltará una excepción
	 * controlada
	 * @param id_user - ID del usuario con sesión actual
	 * @param user - Nombre del usuario con sesión actual
	 * @param canal - Nombre del canal sobre el que se desplegarán las opciones
	 * @throws Exception
	 */
	public static void opcionesCanal(int id_user, String user, String canal) throws Exception
	{
		int op = -1;
		cs = currCon.prepareCall("{ ? = call P6.GET_ID_CANAL(?) }");
		cs.registerOutParameter(1, Types.INTEGER);
		cs.setString(2, canal);
		cs.executeUpdate();
		int id_canal = cs.getInt(1);

		while(op != 9)
		{
			while(op < 1 || 9 < op)
			{
				System.out.print("--------------------------------------------------\n" + 
					"Elija una opcion para el canal " + canal + ", " + user + "\n" +
					"\t1 - Ver información general\n" +
					"\t2 - Lista de videos\n" + 
					"\t3 - Ver video\n" + 
					"\t4 - Crear video\n" + 
					"\t5 - Cambiar nombre del canal\n" + 
					"\t6 - Seguir canal\n" +
					"\t8 - Eliminar canal\n" + 
					"\t9 - Salir\n" +  
					"Opcion: ");
				op = (int) reader.next().charAt(0);
				op -= 48;
			}
			if(op == 1)
			{ // 1 - Ver información general
				cs = currCon.prepareCall("{ ? = call P6.INFORMACION_CANAL(?) }");
				cs.registerOutParameter(1, OracleTypes.CURSOR);
				cs.setInt(2, id_canal);
				cs.executeUpdate();
				ResultSet rs = (ResultSet) cs.getObject(1);
				rs.next();
				System.out.println("Nombre: " + rs.getString("Nombre") + 
						"\nAutor: " + rs.getString("propietario") + 
						"\nFecha de creacion: " + rs.getDate("fechadecreacion"));
				
				cs = currCon.prepareCall("{ ? = call P6.Ver_numero_de_seguidores(?) }");
				cs.registerOutParameter(1, Types.INTEGER);
				cs.setInt(2, id_canal);
				cs.executeUpdate();
				System.out.println("Numero de seguidores: " + cs.getInt(1));
				
				cs = currCon.prepareCall("{ ? = call P6.Ver_numero_de_videos(?) }");
				cs.registerOutParameter(1, Types.INTEGER);
				cs.setInt(2, id_canal);
				cs.executeUpdate();
				System.out.println("Numero de videos: " + cs.getInt(1));
				
				reader.nextLine();
				System.out.print("Pulse Intro para continuar...");
				reader.nextLine();
				op = 0;
			}
			else if (op == 2)
			{ // 2 - Lista de videos
				cs = currCon.prepareCall("{ ? = call P6.LISTA_VIDEOS(?) }");
				cs.registerOutParameter(1, OracleTypes.CURSOR);
				cs.setInt(2, id_canal);
				cs.executeUpdate();
				ResultSet rs = (ResultSet)cs.getObject(1);
				while(rs.next())
					System.out.println("Video: " + rs.getString("nombre") + ", Duracion: " + rs.getInt("Duracion") + " minutos");

				reader.nextLine();
				System.out.print("Pulse Intro para continuar...");
				reader.nextLine();
				op = 0;
			}
			else if (op == 3)
			{ // 3 - Ver video
				System.out.print("Nombre del video: ");
				String video = reader.next();
				cs = currCon.prepareCall("{ call P6.VER_VIDEO(?,?) }");
				cs.setInt(1, id_canal);
				cs.setString(2, video);
				try
				{
					op = 0;
					cs.executeUpdate();
					opcionesVideo(id_user, user, canal, id_canal, video);
				}
				catch(SQLException ee) { System.out.println(ee.getMessage()); }
			}
			else if (op == 4)
			{ // 4 - Crear video
				cs = currCon.prepareCall("{ call P6.VER_SI_PROPIETARIO(?, ?) }"); 
				cs.setString(1, user);
				cs.setString(2, canal);
				try
				{
					cs.executeUpdate();
					System.out.print("Nombre: ");
					String nombreVideo = reader.next();
					System.out.print("Duracion: ");
					int duracionVideo = Integer.parseInt(reader.next());
					cs = currCon.prepareCall("{ call P6.CREAR_VIDEO(?, ?, ?) }");
					cs.setString(1, nombreVideo);
					cs.setInt(2, duracionVideo);
					cs.setInt(3, id_canal);
					cs.executeUpdate();
					reader.nextLine();
					System.out.print("Pulse Intro para continuar...");
					reader.nextLine();
					opcionesVideo(id_user, user, canal, id_canal, nombreVideo);
					op = 0;
				}
				catch(SQLException ee) 
				{ 
					System.out.println(ee.getMessage()); 
					op = 0;
					reader.nextLine();
					System.out.print("Pulse Intro para continuar...");
					reader.nextLine();
				}
			}
			else if (op == 5)
			{ // 5 - Cambiar nombre del canal
				cs = currCon.prepareCall("{ call P6.VER_SI_PROPIETARIO(?, ?) }"); 
				cs.setString(1, user);
				cs.setString(2, canal);
				try
				{
					cs.executeUpdate();
					cs = currCon.prepareCall("{ call P6.ACTUALIZAR_CANAL(?, ?) }"); 
					System.out.print("Nuevo nombre: ");
					String nuevoCanal = reader.next();
					cs.setString(1, nuevoCanal);
					cs.setInt(2, id_canal);
					cs.executeUpdate();
					canal = nuevoCanal;
					op = 0;
				}
				catch(SQLException ee) 
				{ 
					System.out.println(ee.getMessage()); 
					op = 0;
				}
				
				reader.nextLine();
				System.out.print("Pulse Intro para continuar...");
				reader.nextLine();
			}
			else if (op == 6)
			{ // 6 - Seguir canal
				cs = currCon.prepareCall("{ call P6.SEGUIR_CANAL(?, ?) }"); 
				cs.setInt(1, id_user);
				cs.setInt(2, id_canal);
				try
				{
					cs.executeUpdate();
					op = 0;
					System.out.println("Siguiendo al canal");
					
				}
				catch(SQLException ee) 
				{ 
					System.out.println(ee.getMessage()); 
					op = 0;
				}
				
				reader.nextLine();
				System.out.print("Pulse Intro para continuar...");
				reader.nextLine();
			}
			else if (op == 8)
			{ // 8 - Eliminar canal
				cs = currCon.prepareCall("{ call P6.VER_SI_PROPIETARIO(?, ?) }"); 
				cs.setString(1, user);
				cs.setString(2, canal);
				try
				{
					cs.executeUpdate();
					cs = currCon.prepareCall("{ call P6.ELIMINAR_CANAL(?, ?) }");
					cs.setString(1, user);
					cs.setString(2, canal);	
					System.out.println("Eliminando canal...");
					cs.executeUpdate();
					op = 9;
				}
				catch(SQLException ee) 
				{ 
					System.out.println(ee.getMessage()); 
					op = 0;
				}
				
				reader.nextLine();
				System.out.print("Pulse Intro para continuar...");
				reader.nextLine();
			}
		}
	}

	
	/**
	 * Muestra las opciones iniciales una vez que el usuario se ha registrado o iniciado sesión
	 * 		1. Ver lista de canales
	 * 		2. Ver un canal
	 * 		3. Crear un canal
	 * 		4. Lista de usuarios
	 * 		9. Salir del sistema
	 * @param user - Nombre del usuario con sesión actual
	 * @throws Exception
	 */
	public static void entradaSistema(String user) throws Exception
	{
		int op = -1;
		cs = currCon.prepareCall("{ ? = call P6.GET_ID_USUARIO(?) }");
		cs.registerOutParameter(1, Types.INTEGER);
		cs.setString(2, user);
		cs.executeUpdate();
		int id_user = cs.getInt(1);
		while(op != 9)
		{
			while(op < 1 || 9 < op)
			{
				System.out.print("--------------------------------------------------\n" + 
					"Elija una opcion, " + user + "\n" +
					"\t1 - Lista de canales\n" +
					"\t2 - Ver canal\n" + 
					"\t3 - Crear canal\n" +
					"\t4 - Lista de usuarios\n" + 
					"\t9 - Salir\n" +  
					"Opcion: ");
				op = reader.nextInt();
			}
			if(op == 1)
			{ // 1 - Lista de canales
				ResultSet rs = null;
				cs = currCon.prepareCall("{ ? = call P6.LISTA_CANALES }");
				cs.registerOutParameter(1, OracleTypes.CURSOR);
				cs.executeUpdate();
				rs = (ResultSet)cs.getObject(1);
				while(rs.next())
				{
					System.out.println("Canal: " + rs.getString("nombre") + ", Autor: " + rs.getString("propietario"));
				}
				op = 0;
				reader.nextLine();
				System.out.print("Pulse Intro para continuar...");
				reader.nextLine();
			}
			else if(op == 2)
			{ // 2 - Ver canal
				System.out.print("Nombre del canal: ");
				String canal = reader.next();
				cs = currCon.prepareCall("{ call P6.VER_CANAL(?) }");
				cs.setString(1, canal);
				try
				{
					op = 0;
					cs.executeUpdate();
					opcionesCanal(id_user,user,canal);
					
				}
				catch(SQLException ee)
				{
					System.out.println(ee.getMessage());
					reader.nextLine();
					System.out.print("Pulse Intro para continuar...");
					reader.nextLine();
				}
			}
			else if (op == 3)
			{ // 3 - Crear canal
				System.out.print("Nombre del canal: ");
				String canal = reader.next();
				cs = currCon.prepareCall("{ call P6.CREAR_CANAL(?, ?) }");
				cs.setString(1, user);
				cs.setString(2, canal);
				try
				{
					op = 0;
					cs.executeUpdate();
					System.out.println("Canal creado con exito");
					reader.nextLine();
					System.out.print("Pulse Intro para continuar...");
					reader.nextLine();
					opcionesCanal(id_user,user,canal);
				}
				catch(SQLException ee)
				{
					System.out.println(ee.getMessage());
					reader.nextLine();
					System.out.print("Pulse Intro para continuar...");
					reader.nextLine();
				}
			}
			else if (op == 4)
			{ // 4 - Lista de usuarios
				cs = currCon.prepareCall("{ ? = call P6.LISTA_USUARIOS }");
				cs.registerOutParameter(1, OracleTypes.CURSOR);
				cs.executeUpdate();
				ResultSet rs = (ResultSet) cs.getObject(1);
				while(rs.next())
				{
					cs = currCon.prepareCall("{ ? = call P6.GET_ID_USUARIO(?) }");
					cs.registerOutParameter(1, Types.INTEGER);
					cs.setString(2, rs.getString("nombre"));
					cs.executeUpdate();
					int id_userV = cs.getInt(1);
					cs = currCon.prepareCall("{ ? = call P6.VER_NUMERO_DE_CANALES(?) }");
					cs.registerOutParameter(1, Types.INTEGER);
					cs.setInt(2, id_userV);
					cs.executeUpdate();
					int num_canales = cs.getInt(1);
					System.out.println("Usuario: " + rs.getString("nombre") + 
										" - Num. canales: " + num_canales);
				}
				reader.nextLine();
				System.out.print("Pulse Intro para continuar...");
				reader.nextLine();
				op = 0;
			}
		}
	}

	
	/**
	 * Contiene las opciones para registro y entrada al sistema
	 * @throws Exception
	 */
	public static void login() throws Exception
	{
		int op = -1;
		while(op < 1 || 3 < op)
		{
			System.out.print("--------------------------------------------------\n" + 
				"Elija una opcion\n" + 
				"\t1 - Entrar al sistema\n" + 
				"\t2 - Registro en el sistema\n" + 
				"Opcion: ");
			op = reader.nextInt();
		}

		if(op == 1)
		{ // 1 - Entrar al sistema 
			System.out.print("Usuario: ");
			String user = reader.next();
			System.out.print("Password: ");
			String pass = reader.next();
			// Pasar credenciales por bd
			cs = currCon.prepareCall("{ ? = call P6.ACCESO_AL_SISTEMA(?, ?) }");
			cs.registerOutParameter(1, Types.INTEGER);
			cs.setString(2, user);
			cs.setString(3, pass);
			cs.executeUpdate();
			if(cs.getInt(1) == 1)
				entradaSistema(user);
			else
				System.out.println("Credenciales incorrectas");
		}
		else if(op == 2)
		{ // 2 - Registro en el sistema
			System.out.print("Usuario: ");
			String user = reader.next();
			System.out.print("E-mail: ");
			String email = reader.next();
			System.out.print("Password: ");
			String pass = reader.next();
			// Pasar registro por bd
			int premium = -1;
			while(premium < 0 || 1 < premium)
			{
				System.out.print( "Elija una opcion\n" + 
					"\t0 - Usuario normal\n" + 
					"\t1 - Usuario premium\n" + 
					"Opcion: ");
				premium = reader.nextInt();
			}
			cs = currCon.prepareCall("{ call P6.REGISTRO_EN_EL_SISTEMA(?, ?, ?, ?) }");
			cs.setString(1, user);
			cs.setString(2, email);
			cs.setString(3, pass);
			cs.setInt(4, premium);
			try
			{
				cs.executeUpdate();
				entradaSistema(user);
			}
			catch(SQLException ee){
				System.out.println(ee.getMessage());
			}
			
		}
	}

	/**
	 * Punto de inicio de la aplicación.
	 * @param args
	 * @throws Exception
	 */
	public static void main(String[] args) throws Exception
	{
		System.out.println("Hola, bienvenido al gestor de videos");
		
		while(true)
		{ // Se crea una sesión por cada vez que un usuario entra a las 
		  // opciones de login/registro
			currCon = new OracleConnection().dbConnector();
			login();
			currCon.close();
		}
	}
	
}

