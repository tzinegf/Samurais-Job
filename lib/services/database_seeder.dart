import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';
import '../models/subcategory_model.dart';
import '../models/catalog_service_model.dart';

class DatabaseSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seed() async {
    final data = _getData();

    for (var catData in data) {
      // 1. Create or Get Category
      final categorySlug = _slugify(catData.name);
      
      // Check if exists
      final catQuery = await _firestore
          .collection('categories')
          .where('slug', isEqualTo: categorySlug)
          .get();

      String categoryId;
      if (catQuery.docs.isNotEmpty) {
        categoryId = catQuery.docs.first.id;
        print('Category exists: ${catData.name}');
      } else {
        final catRef = _firestore.collection('categories').doc();
        categoryId = catRef.id;
        final category = CategoryModel(
          id: categoryId,
          name: catData.name,
          slug: categorySlug,
          icon: catData.icon,
        );
        await catRef.set(category.toMap());
        print('Created Category: ${catData.name}');
      }

      // 2. Process Subcategories
      for (var subData in catData.subcategories) {
        final subSlug = _slugify(subData.name);
        
        final subQuery = await _firestore
            .collection('subcategories')
            .where('slug', isEqualTo: subSlug)
            .where('categoria_id', isEqualTo: categoryId)
            .get();

        String subcategoryId;
        if (subQuery.docs.isNotEmpty) {
          subcategoryId = subQuery.docs.first.id;
          print('  Subcategory exists: ${subData.name}');
        } else {
          final subRef = _firestore.collection('subcategories').doc();
          subcategoryId = subRef.id;
          final subcategory = SubcategoryModel(
            id: subcategoryId,
            categoryId: categoryId,
            name: subData.name,
            slug: subSlug,
          );
          await subRef.set(subcategory.toMap());
          print('  Created Subcategory: ${subData.name}');
        }

        // 3. Process Services
        for (var serviceName in subData.services) {
          final serviceSlug = _slugify(serviceName);

          final servQuery = await _firestore
              .collection('services')
              .where('slug', isEqualTo: serviceSlug)
              .where('subcategoria_id', isEqualTo: subcategoryId)
              .get();

          if (servQuery.docs.isNotEmpty) {
             print('    Service exists: $serviceName');
          } else {
            final servRef = _firestore.collection('services').doc();
            final service = CatalogServiceModel(
              id: servRef.id,
              subcategoryId: subcategoryId,
              name: serviceName,
              slug: serviceSlug,
              shortDescription: serviceName, // Default description
              active: true,
            );
            await servRef.set(service.toMap());
            print('    Created Service: $serviceName');
          }
        }
      }
    }
  }

  String _slugify(String text) {
    var slug = text.toLowerCase().trim();
    slug = slug.replaceAll(RegExp(r'[áàãâä]'), 'a');
    slug = slug.replaceAll(RegExp(r'[éèêë]'), 'e');
    slug = slug.replaceAll(RegExp(r'[íìîï]'), 'i');
    slug = slug.replaceAll(RegExp(r'[óòõôö]'), 'o');
    slug = slug.replaceAll(RegExp(r'[úùûü]'), 'u');
    slug = slug.replaceAll(RegExp(r'[ç]'), 'c');
    slug = slug.replaceAll(RegExp(r'[ñ]'), 'n');
    slug = slug.replaceAll(RegExp(r'[^a-z0-9]'), '-');
    slug = slug.replaceAll(RegExp(r'-+'), '-');
    return slug;
  }

  List<_CategoryData> _getData() {
    return [
      _CategoryData(
        'Assistência Técnica',
        '🛠️',
        [
          _SubcategoryData('Eletrônicos', [
            'Conserto de TV',
            'Conserto de Som',
            'Conserto de Home Theater',
            'Conserto de Câmeras',
            'Conserto de Videogame',
          ]),
          _SubcategoryData('Eletrodomésticos', [
            'Conserto de Geladeira',
            'Conserto de Fogão / Cooktop',
            'Conserto de Microondas',
            'Conserto de Lava-louça',
            'Conserto de Máquina de Lavar',
            'Conserto de Secadora',
          ]),
          _SubcategoryData('Informática & Telefonia', [
            'Manutenção de Computador',
            'Manutenção de Notebook',
            'Manutenção de Impressora',
            'Conserto de Celular',
            'Redes e Cabeamento',
            'Telefonia PABX',
          ]),
        ],
      ),
      _CategoryData(
        'Aulas e Cursos',
        '📚',
        [
          _SubcategoryData('Reforço Escolar', [
            'Reforço Escolar',
            'Preparação para Concursos',
            'Pré-Vestibular',
          ]),
          _SubcategoryData('Ensino Superior e Técnico', [
            'Aulas Universitárias',
            'Cursos Profissionalizantes',
          ]),
          _SubcategoryData('Idiomas', [
            'Inglês',
            'Espanhol',
            'Outros Idiomas',
          ]),
          _SubcategoryData('Artes, Tecnologia e Esporte', [
            'Música',
            'Fotografia',
            'Dança',
            'Esportes',
          ]),
          _SubcategoryData('Informática', [
            'Programação',
            'Design',
            'Marketing Digital',
          ]),
        ],
      ),
      _CategoryData(
        'Autos',
        '🚗',
        [
          _SubcategoryData('Manutenção', [
            'Auto Elétrica',
            'Ar-condicionado Automotivo',
            'Mecânica Geral',
            'Funilaria e Pintura',
            'Martelinho de Ouro',
            'Borracharia',
          ]),
          _SubcategoryData('Serviços Veiculares', [
            'Guincho',
            'Insulfilm',
            'Vidraçaria Automotiva',
            'Higienização Automotiva',
          ]),
          _SubcategoryData('Compra e Venda', [
            'Venda de Veículos',
          ]),
        ],
      ),
      _CategoryData(
        'Consultoria & Profissionais',
        '💼',
        [
          _SubcategoryData('Negócios e Finanças', [
            'Consultoria Empresarial',
            'Contabilidade',
            'Assessoria Financeira',
            'Recrutamento e Seleção',
          ]),
          _SubcategoryData('Jurídico', [
            'Advocacia',
            'Mediação de Conflitos',
            'Planejamento Patrimonial',
          ]),
          _SubcategoryData('Serviços Especializados', [
            'Consultoria Especializada',
            'Detetive Particular',
            'Guia de Turismo',
          ]),
        ],
      ),
      _CategoryData(
        'Design, Tecnologia & Marketing',
        '🎨',
        [
          _SubcategoryData('Desenvolvimento', [
            'Sites',
            'Sistemas Web',
            'Aplicativos',
            'Jogos',
          ]),
          _SubcategoryData('Design', [
            'Design Gráfico',
            'UI / UX Design',
            'Criação de Logos',
            'Identidade Visual',
          ]),
          _SubcategoryData('Conteúdo & Audiovisual', [
            'Produção de Conteúdo',
            'Fotografia',
            'Vídeo',
            'Edição de Imagens',
          ]),
        ],
      ),
      _CategoryData(
        'Eventos',
        '🎉',
        [
          _SubcategoryData('Organização', [
            'Assessoria de Eventos',
            'Organização Completa',
          ]),
          _SubcategoryData('Estrutura', [
            'Espaço para Eventos',
            'Equipamentos',
            'Segurança',
          ]),
          _SubcategoryData('Serviços', [
            'Buffet',
            'Bartender',
            'Garçons',
            'Decorador',
            'Florista',
          ]),
          _SubcategoryData('Animação', [
            'DJs',
            'Bandas',
            'Animação Infantil',
          ]),
        ],
      ),
      _CategoryData(
        'Moda, Beleza & Estética',
        '💄',
        [
          _SubcategoryData('Estética', [
            'Limpeza de Pele',
            'Depilação',
            'Design de Sobrancelhas',
            'Micropigmentação',
          ]),
          _SubcategoryData('Cabelo & Barba', [
            'Cabeleireiro',
            'Barbeiro',
            'Maquiagem',
          ]),
          _SubcategoryData('Moda', [
            'Costureira',
            'Alfaiate',
            'Personal Stylist',
          ]),
        ],
      ),
      _CategoryData(
        'Reformas & Reparos',
        '🏗️',
        [
          _SubcategoryData('Construção', [
            'Pedreiro',
            'Empreiteiro',
            'Arquiteto',
            'Engenheiro',
          ]),
          _SubcategoryData('Instalações', [
            'Eletricista',
            'Encanador',
            'Gás',
            'Antenista',
            'Automação Residencial',
          ]),
          _SubcategoryData('Acabamento', [
            'Pintor',
            'Gesso / Drywall',
            'Vidraceiro',
            'Serralheria',
          ]),
          _SubcategoryData('Serviços Gerais', [
            'Marido de Aluguel',
          ]),
          _SubcategoryData('Mudanças', [
            'Montador de Móveis',
          ]),
        ],
      ),
      _CategoryData(
        'Saúde & Bem-Estar',
        '🩺',
        [
          _SubcategoryData('Saúde Física', [
            'Fisioterapia',
            'Nutrição',
            'Quiropraxia',
            'Terapias Alternativas',
          ]),
          _SubcategoryData('Saúde Mental', [
            'Psicólogo',
            'Psicanalista',
            'Coaching',
          ]),
          _SubcategoryData('Cuidados Especiais', [
            'Cuidador de Pessoas',
            'Enfermeiro(a)',
            'Doula',
          ]),
        ],
      ),
      _CategoryData(
        'Serviços Domésticos',
        '🏠',
        [
          _SubcategoryData('Casa', [
            'Diarista',
            'Faxina',
            'Lavanderia',
            'Passadeira',
            'Limpeza de Piscina',
          ]),
          _SubcategoryData('Família', [
            'Babá',
            'Cozinheira',
            'Motorista Particular',
          ]),
          _SubcategoryData('Pets', [
            'Banho e Tosa',
            'Passeador de Cães',
            'Adestrador',
          ]),
        ],
      ),
    ];
  }
}

class _CategoryData {
  final String name;
  final String icon;
  final List<_SubcategoryData> subcategories;

  _CategoryData(this.name, this.icon, this.subcategories);
}

class _SubcategoryData {
  final String name;
  final List<String> services;

  _SubcategoryData(this.name, this.services);
}
