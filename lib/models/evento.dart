part of arista;

class Evento
{
    @NotEmpty()
    @Id () String id;
    
    @NotEmpty()
    @Field () String nombre = 'Nueva Maquina';
    
    @Field () String descripcion = 'Descripcion';
    
    @ReferenceId() List<String> imagenes = [];

    @Range(min: 0)
    @Field () int toneladas;
}

class EvAdmin
{
    @Field() List<String> productores = [];
}



class EventoExportable extends EventoCompleto
{
    @Field() List<VistaExportable> vistas;
}
