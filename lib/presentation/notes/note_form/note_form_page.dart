import 'package:auto_route/auto_route.dart';
import 'package:dartz/dartz.dart';
import 'package:flushbar/flushbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_firebase_ddd_notes/application/notes/note_form/note_form_bloc.dart';
import 'package:flutter_firebase_ddd_notes/presentation/notes/note_form/misc/todo_item_presentation_classes.dart';
import 'package:flutter_firebase_ddd_notes/presentation/notes/note_form/widgets/add_todo_tile_widget.dart';
import 'package:flutter_firebase_ddd_notes/presentation/notes/note_form/widgets/body_field_widget.dart';
import 'package:flutter_firebase_ddd_notes/presentation/notes/note_form/widgets/color_field_widget.dart';
import 'package:flutter_firebase_ddd_notes/presentation/routes/router.gr.dart'
    as r;
import 'package:provider/provider.dart';

import '../../../domain/notes/note.dart';
import '../../../injection.dart';
import 'widgets/todo_list_widget.dart';

class NoteFormPage extends StatelessWidget {
  final Note editedNote;

  const NoteFormPage({
    Key key,
    @required this.editedNote,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<NoteFormBloc>()
        ..add(NoteFormEvent.initialized(optionOf(editedNote))),
      child: BlocConsumer<NoteFormBloc, NoteFormState>(
          listenWhen: (previous, current) =>
              previous.saveFailureOrSuccessOption !=
              current.saveFailureOrSuccessOption,
          listener: (context, state) {
            state.saveFailureOrSuccessOption.fold(
              () => {},
              (either) {
                either.fold(
                  (failure) => FlushbarHelper.createError(
                    message: failure.map(
                      insufficientPermission: (_) => 'Insuficient permissions',
                      unableToUpdate: (_) =>
                          "Couldn't update the note. Was it deleted form another user",
                      unexpected: (_) =>
                          'Unexpected error. please contact support',
                    ),
                  ).show(context),
                  (_) {
                    ExtendedNavigator.of(context).popUntil((route) =>
                        route.settings.name == r.Routes.notesOverviewPage);
                  },
                );
              },
            );
          },
          buildWhen: (previous, current) =>
              previous.isSaving != current.isSaving,
          builder: (context, state) {
            return Stack(
              children: [
                const NoteFormPageScaffold(),
                SavingInProgressOverlay(
                  isSaving: state.isSaving,
                )
              ],
            );
          }),
    );
  }
}

class SavingInProgressOverlay extends StatelessWidget {
  final bool isSaving;

  const SavingInProgressOverlay({
    Key key,
    @required this.isSaving,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !isSaving,
      child: AnimatedContainer(
          color: isSaving ? Colors.black.withOpacity(0.8) : Colors.transparent,
          duration: const Duration(milliseconds: 150),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Visibility(
            visible: isSaving,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  'Saving',
                  style: Theme.of(context).textTheme.bodyText2.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                ),
              ],
            ),
          )),
    );
  }
}

class NoteFormPageScaffold extends StatelessWidget {
  const NoteFormPageScaffold({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<NoteFormBloc, NoteFormState>(
          buildWhen: (previous, current) =>
              previous.isEditing != current.isEditing,
          builder: (context, state) {
            return Text(
              state.isEditing ? 'Edit a note' : 'Create a note',
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              context.bloc<NoteFormBloc>().add(const NoteFormEvent.saved());
            },
          )
        ],
      ),
      body: BlocBuilder<NoteFormBloc, NoteFormState>(
        buildWhen: (previous, current) =>
            previous.showErrorMessages != current.showErrorMessages,
        builder: (context, state) {
          return ChangeNotifierProvider(
            create: (_) => FormTodos(),
            child: Form(
              autovalidateMode: state.showErrorMessages
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
              child: SingleChildScrollView(
                child: Column(
                  children: const [
                    BodyField(),
                    ColorField(),
                    TodoList(),
                    AddTodoTile(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
